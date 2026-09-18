data "aws_partition" "current" {}
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}
resource "aws_ecs_cluster" "this" {
  name = var.name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}
resource "aws_ecs_task_definition" "api" {
  depends_on               = [aws_iam_role_policy_attachment.execution]
  family                   = "${var.name}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions = jsonencode([{
    name                   = "api"
    image                  = var.container_image
    essential              = true
    user                   = var.container_user != "" ? var.container_user : null
    readonlyRootFilesystem = var.readonly_root_filesystem
    linuxParameters = {
      initProcessEnabled = true
      capabilities       = { drop = var.readonly_root_filesystem ? ["ALL"] : [] }
    }
    stopTimeout  = 60
    portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
    environment = [for key, value in var.container_environment : {
      name  = key
      value = value
    }]
    healthCheck = {
      command     = length(var.health_check_command) > 0 ? var.health_check_command : ["CMD-SHELL", "wget -qO- http://127.0.0.1:${var.container_port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 20
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = var.log_group_name
        awslogs-region        = var.region
        awslogs-stream-prefix = "api"
      }
    }
  }])
  tags = var.tags
}
