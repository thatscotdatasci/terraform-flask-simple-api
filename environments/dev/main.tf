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

module "cicd_iam" {
  source = "../../modules/iam"

  iam_role_name = "${local.item_suffix}-cicd"
  codebuild_project_name = "${local.item_suffix}"
  region = "${var.region}"
  ecr_repo = "${var.ecr_repo}"
}

module "codebuild" {
  source = "github.com/thatscotdatasci/terraform-module-aws-codebuild//modules/codebuild_ecr"

  region = "${var.region}"
  account_id = "${var.account_id}"
  repo_name = "${var.ecr_repo}"
  github_project_url = "${var.github_project_url}"
  project_name = "${local.item_suffix}"
  environment_tag = "${var.environment}"
  iam_role_arn = "${module.cicd_iam.arn}"
}
