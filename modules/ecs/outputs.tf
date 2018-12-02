output "service_id" {
  value = "${aws_ecs_service.this.id}"
}

output "service_name" {
  value = "${aws_ecs_service.this.name}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.this.id}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.this.name}"
}

output "task_def_arn" {
  value = "${aws_ecs_task_definition.this.arn}"
}

output "task_def_family" {
  value = "${aws_ecs_task_definition.this.family}"
}

output "task_def_revision" {
  value = "${aws_ecs_task_definition.this.revision}"
}
