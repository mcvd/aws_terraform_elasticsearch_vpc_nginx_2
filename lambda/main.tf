resource "null_resource" "pip" {
  triggers = {
    main         = base64sha256(file("${path.module}/src/main.py"))
    requirements = base64sha256(file("${path.module}/src/requirements.txt"))
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/src/requirements.txt -t ${path.module}/src/"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/lambda.zip"

  depends_on = [null_resource.pip]
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_readonly_es_post_put_only"
  assume_role_policy = file("${path.module}/policies/lambda_trust_policy.json")
}

resource "aws_iam_policy" "lambda_policy" {
  name = "s3_readonly_es_post_put_only"
  policy = file("${path.module}/policies/s3_readonly_es_post_put_only.json")
}

data "aws_iam_policy" "aws_lambda_vpc" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_es" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.aws_lambda_vpc.arn
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "danilo_test_s3_to_es"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.6"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

