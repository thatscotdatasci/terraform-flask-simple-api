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

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${local.item_suffix}-codepipeline"
  acl           = "private"
  force_destroy = true
}

resource "aws_ecr_repository" "ecr_repository" {
  name = "${local.item_suffix}"
}

data "template_file" "cicd_iam_policy" {
  template = "${file("../../templates/cicd_iam_policy.tpl")}"

  vars {
    region                 = "${var.region}"
    s3_codepipeline_bucket = "${aws_s3_bucket.codepipeline_bucket.arn}"
    codebuild_project_name = "${local.item_suffix}"
    ecr_repo               = "${aws_ecr_repository.ecr_repository.name}"
  }
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
  ecs_cluster_name       = "${var.ecs_cluster_name}"
  ecs_service_name       = "${var.ecs_service_name}"
}
