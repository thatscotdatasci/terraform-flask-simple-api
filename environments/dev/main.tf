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

data "template_file" "cicd_iam_policy" {
  template = "${file("../../templates/cicd_iam_policy.tpl")}"

  vars {
    region = "${var.region}"
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
  github_project_url = "${var.github_project_url}"
  project_name = "${local.item_suffix}"
  environment_tag = "${var.environment}"
  iam_role_arn = "${module.cicd_iam_role.arn}"
}
