terraform {
  backend "s3" {}
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

locals {
  item_suffix = "${join("-", list(var.user, var.project, var.environment))}"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${local.item_suffix}-codepipeline"
  acl = "private"
  force_destroy = true
}

data "template_file" "cicd_iam_policy" {
  template = "${file("../../templates/cicd_iam_policy.tpl")}"

  vars {
    region = "${var.region}"
    s3_codepipeline_bucket = "${aws_s3_bucket.codepipeline_bucket.arn}"
    codebuild_project_name = "${local.item_suffix}"
    ecr_repo = "${var.ecr_repo}"
  }
}

module "cicd_iam_role" {
  source = "github.com/thatscotdatasci/terraform-module-aws-iam//modules/iam_role"

  role_name = "${local.item_suffix}-cicd"
  assume_role_policy = "${file("../../files/cicd_iam_role.json")}"
  force_detach_policies = "True"
}

module "cicd_iam_policy" {
  source = "github.com/thatscotdatasci/terraform-module-aws-iam//modules/iam_policy"

  role = "${module.cicd_iam_role.name}"
  policy = "${data.template_file.cicd_iam_policy.rendered}"
}

module "codebuild" {
  source = "github.com/thatscotdatasci/terraform-module-aws-codebuild//modules/codebuild_ecr"

  region = "${var.region}"
  account_id = "${var.account_id}"
  repo_name = "${var.ecr_repo}"
  container_name = "${var.ecs_container_name}"
  github_project_url = "${var.github_project_url}"
  project_name = "${local.item_suffix}"
  environment_tag = "${var.environment}"
  iam_role_arn = "${module.cicd_iam_role.arn}"
}

module "codepipeline" {
  source = "github.com/thatscotdatasci/terraform-module-aws-codepipeline//modules/codepipeline_ecs"

  codepipeline_name = "${local.item_suffix}"
  iam_role_arn = "${module.cicd_iam_role.arn}"
  s3_artifact_bucket_arn = "${aws_s3_bucket.codepipeline_bucket.id}"
  github_owner = "${var.github_owner}"
  github_repo = "${var.github_repo}"
  github_branch = "${var.github_branch}"
  github_poll = true
  github_oauth = "${var.github_oauth}"
  codebuild_name = "${module.codebuild.id}"
  ecs_cluster_name = "${var.ecs_cluster_name}"
  ecs_service_name = "${var.ecs_service_name}"
}
