data "template_file" "iam_policy" {
  template = "${file("${path.module}/templates/cicd_iam_policy.tpl")}"

  vars {
    region = "${var.region}"
    codebuild_project_name = "${var.codebuild_project_name}"
    ecr_repo = "${var.ecr_repo}"
  }
}

resource "aws_iam_role" "iam_role" {
  name = "${var.iam_role_name}"
  assume_role_policy = "${file("${path.module}/files/cicd_iam_role.json")}"
  force_detach_policies = "True"
}

resource "aws_iam_role_policy" "iam_policy" {
  role = "${aws_iam_role.iam_role.name}"
  policy = "${data.template_file.iam_policy.rendered}"
}

output "arn" { value =  "${aws_iam_role.iam_role.arn}" }
