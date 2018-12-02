terraform {
  backend "s3" {}
}

provider "github" {
  organization = ""
  token        = ""
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

locals {
  item_suffix = "${join("-", list(var.user, var.project, var.environment))}"
}

data "template_file" "cicd_iam_policy" {
  template = "${file("../../templates/cicd_iam_policy.tpl")}"

  vars {
    region                 = "${var.region}"
    s3_codepipeline_bucket = "${aws_s3_bucket.codepipeline_bucket.arn}"
    codebuild_project_name = "${local.item_suffix}"
    ecr_repo               = "${aws_ecr_repository.ecr_repository.name}"
    ecs_iam_arn            = "${module.ecs_iam_role.arn}"
  }
}

data "template_file" "ecs_service_definitions" {
  template = "${file("../../templates/ecs_service_definitions.json")}"

  vars {
    container_name = "${var.ecs_container_name}"
    container_tag  = "latest"
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${local.item_suffix}-codepipeline"
  acl           = "private"
  force_destroy = true
}

resource "aws_ecr_repository" "ecr_repository" {
  name = "${local.item_suffix}"
}

module "aws_ecs" {
  source = "../../modules/ecs"

  service_name      = "${local.item_suffix}"
  count             = 0
  iam_arn           = "${module.ecs_iam_role.arn}"
  exec_iam_arn      = "${module.cicd_iam_role.arn}"
  cluster_name      = "${local.item_suffix}"
  task_def_name     = "${local.item_suffix}"
  service_definiton = "${data.template_file.ecs_service_definitions.rendered}"
}

module "cicd_iam_role" {
  source = "github.com/thatscotdatasci/terraform-module-aws-iam.git?ref=v1.0.1//modules/iam_role"

  role_name             = "${local.item_suffix}-cicd"
  assume_role_policy    = "${file("../../files/cicd_iam_role.json")}"
  force_detach_policies = "True"
}

module "cicd_iam_policy" {
  source = "github.com/thatscotdatasci/terraform-module-aws-iam.git?ref=v1.0.1//modules/iam_policy"

  name   = "${local.item_suffix}-cicd"
  policy = "${data.template_file.cicd_iam_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach_cicd_policy" {
  role       = "${module.cicd_iam_role.name}"
  policy_arn = "${module.cicd_iam_policy.id}"
}

resource "aws_iam_role_policy_attachment" "attach_ecs_full_access_policy" {
  role       = "${module.cicd_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_ecs_task_execution_policy" {
  role       = "${module.cicd_iam_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "ecs_iam_role" {
  source = "github.com/thatscotdatasci/terraform-module-aws-iam.git?ref=v1.0.1//modules/iam_role"

  role_name             = "${local.item_suffix}-ecs"
  assume_role_policy    = "${file("../../files/ecs_iam_role.json")}"
  force_detach_policies = "True"
}

module "codebuild" {
  source = "github.com/thatscotdatasci/terraform-module-aws-codebuild.git?ref=v1.0.0//modules/codebuild_ecr"

  region             = "${var.region}"
  account_id         = "${var.account_id}"
  repo_name          = "${aws_ecr_repository.ecr_repository.name}"
  container_name     = "${var.ecs_container_name}"
  github_project_url = "${var.github_project_url}"
  project_name       = "${local.item_suffix}"
  environment_tag    = "${var.environment}"
  iam_role_arn       = "${module.cicd_iam_role.arn}"
}

module "codepipeline" {
  source = "github.com/thatscotdatasci/terraform-module-aws-codepipeline.git?ref=v1.1.2//modules/codepipeline_ecs"

  codepipeline_name      = "${local.item_suffix}"
  iam_role_arn           = "${module.cicd_iam_role.arn}"
  s3_artifact_bucket_arn = "${aws_s3_bucket.codepipeline_bucket.id}"
  github_owner           = "${var.github_owner}"
  github_repo            = "${var.github_repo}"
  github_branch          = "${var.github_branch}"
  github_poll            = true
  github_oauth           = "${var.github_oauth}"
  codebuild_name         = "${module.codebuild.id}"
  ecs_cluster_name       = "${module.aws_ecs.cluster_name}"
  ecs_service_name       = "${module.aws_ecs.service_name}"
}
