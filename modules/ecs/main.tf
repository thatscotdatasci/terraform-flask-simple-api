resource "aws_ecs_cluster" "this" {
  name = "${var.cluster_name}"
}

resource "aws_ecs_service" "this" {
  name                = "${var.service_name}"
  cluster             = "${aws_ecs_cluster.this.id}"
  task_definition     = "${aws_ecs_task_definition.this.arn}"
  desired_count       = "${var.count}"
  scheduling_strategy = "REPLICA"
  launch_type         = "FARGATE"

//  lifecycle {
//    ignore_changes = ["desired_count"]
//  }

  network_configuration {
    subnets          = ["subnet-0b246f7acd6f06d61", "subnet-0da4d5f95588a0f1e"]
    security_groups  = ["sg-0c1e9a73e29e8d7b9"]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}"
  container_definitions    = "${var.service_definiton}"
  // task_role_arn            = "${var.iam_arn}"
  execution_role_arn       = "${var.exec_iam_arn}"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
}
