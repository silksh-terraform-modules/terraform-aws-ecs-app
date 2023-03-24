locals {
  port_mappings = length(var.container_port_secondary) > 0 ? [ 
    {
      containerPort = var.container_port
      hostPort      = var.host_port
      protocol      = var.service_protocol
    },
    {
      containerPort = var.container_port_secondary
      hostPort      = var.host_port
      protocol      = var.service_protocol
    }
  ]:[
    {
      containerPort = var.container_port
      hostPort      = var.host_port
      protocol      = var.service_protocol
    }
  ]
  
}

module "container" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"
  
  container_name  = var.service_name
  container_image = "${var.ecr_repository_url}:${var.docker_image_tag}"

  container_cpu = var.cpu_limit
  container_memory = var.memory_limit

  essential = true

  log_configuration = {
    logDriver = "awslogs",
    options = {
      awslogs-region = var.aws_region,
      awslogs-group = var.cloudwatch_log_group,
      awslogs-stream-prefix = var.env_name,
      awslogs-multiline-pattern = var.cloudwatch_multiline_pattern
    }
  }
  
  port_mappings = length(var.service_dns_name) > 0 ? local.port_mappings : null

  map_secrets = var.ssm_variables

  map_environment = var.task_variables
  
  mount_points = var.mount_points

  environment_files = var.environment_files

  healthcheck = var.healthcheck

}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.env_name}"
  cpu                      = var.cpu_limit
  execution_role_arn       = var.ecs_role_arn
  memory                   = var.memory_limit
  network_mode             = "bridge"
  task_role_arn            = var.ecs_role_arn

  container_definitions = module.container.json_map_encoded_list
  
  lifecycle {
    create_before_destroy = true
  }

    dynamic "volume" {
    for_each = var.local_volumes
    content {
      name = volume.value.volume_name
      host_path = volume.value.host_path
      
    }
  }

  dynamic "volume" {
    for_each = var.efs_volumes
    content {
      name = volume.value.efs_volume_name

      efs_volume_configuration {
        file_system_id = volume.value.efs_file_system_id
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = volume.value.efs_access_point_id
        }
      }
    }
  }
}
