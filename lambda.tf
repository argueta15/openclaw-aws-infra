# lambda.tf

# Comprimimos el código JS de Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM Role para Lambda (necesita leer SQS y levantar EC2)
resource "aws_iam_role" "lambda_role" {
  name = "openclaw-lambda-worker-trigger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "openclaw-lambda-ec2-policy"
  description = "Permite a Lambda levantar instancias Spot"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:RunInstances",
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}

# La Lambda
resource "aws_lambda_function" "worker_trigger" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "openclaw-worker-trigger"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      WORKER_AMI_ID        = data.aws_ami.ubuntu_arm.id
      WORKER_INSTANCE_TYPE = var.worker_node_instance_type
      SECURITY_GROUP_ID    = aws_security_group.openclaw_sg.id
      SUBNET_ID            = data.aws_subnets.default.ids[0]
    }
  }
}

# Mapeamos la Lambda para que escuche SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.openclaw_jobs.arn
  function_name    = aws_lambda_function.worker_trigger.arn
  batch_size       = 1 # 1 job = 1 worker (simplificado)
}
