variable "user" {}
variable "project" {}
variable "environment" {}

variable "account_id" {}
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "eu-west-2"
}

variable "ecr_repo" {}
variable "ecs_container_name" {}
variable "ecs_cluster_name" {}
variable "ecs_service_name" {}

variable "github_owner" {}
variable "github_repo" {}
variable "github_project_url" {}
variable "github_branch" {}
variable "github_oauth" {}
