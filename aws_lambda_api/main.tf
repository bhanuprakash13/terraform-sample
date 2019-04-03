# Based on: https://www.terraform.io/docs/providers/aws/guides/serverless-with-aws-lambda-and-api-gateway.html
# See also: https://github.com/hashicorp/terraform/issues/10157
# See also: https://github.com/carrot/terraform-api-gateway-cors-module/

# This aws_lambda_function is used when invoked with a local zipfile
resource "aws_lambda_function" "local_zipfile" {
  count = "${var.function_s3_bucket == "" ? 1 : 0}"

  filename         = "${var.function_zipfile}"
  source_code_hash = "${var.function_s3_bucket == "" ? "${base64sha256(file("${var.function_zipfile}"))}" : ""}"

  function_name = "${local.prefix_with_domain}"
  handler       = "${var.function_handler}"
  runtime       = "${var.function_runtime}"
  role          = "${aws_iam_role.this.arn}"

  environment {
    variables = "${var.function_env_vars}"
  }
}

# This aws_lambda_function is used when invoked with a zipfile in S3
resource "aws_lambda_function" "s3_zipfile" {
  count = "${var.function_s3_bucket == "" ? 0 : 1}"

  s3_bucket = "${var.function_s3_bucket}"
  s3_key    = "${var.function_zipfile}"

  function_name = "${local.prefix_with_domain}"
  handler       = "${var.function_handler}"
  runtime       = "${var.function_runtime}"
  role          = "${aws_iam_role.this.arn}"

  environment {
    variables = "${var.function_env_vars}"
  }
}

# Terraform isn't particularly helpful when you want to depend on the existence of a resource which may have count 0 or 1, like our functions.
# This is a hacky way of referring to the properties of the function, regardless of which one got created.
# https://github.com/hashicorp/terraform/issues/16580#issuecomment-342573652
locals {
  function_id         = "${element(concat(aws_lambda_function.local_zipfile.*.id, list("")), 0)}${element(concat(aws_lambda_function.s3_zipfile.*.id, list("")), 0)}"
  function_arn        = "${element(concat(aws_lambda_function.local_zipfile.*.arn, list("")), 0)}${element(concat(aws_lambda_function.s3_zipfile.*.arn, list("")), 0)}"
  function_invoke_arn = "${element(concat(aws_lambda_function.local_zipfile.*.invoke_arn, list("")), 0)}${element(concat(aws_lambda_function.s3_zipfile.*.invoke_arn, list("")), 0)}"
}
