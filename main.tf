variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "lambda_path" {
  description = "Path to lambda function"
  type        = string
  default     = "lambda/GigDiary.zip"
}

resource "aws_lambda_function" "gig_diary_function" {
  filename         = var.lambda_path
  function_name    = "GigDiaryFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "GigDiary"
  runtime          = "dotnet8"
  timeout          = 60
  memory_size      = 256
  package_type     = "Zip"
  source_code_hash = filebase64sha256(var.lambda_path)
}

resource "aws_iam_role" "lambda_role" {
  name = "GigDiaryLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "GigDiaryDynamoDBPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.gigs.arn
      }
    ]
  })
}

resource "aws_dynamodb_table" "gigs" {
  name         = "Gigs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}

resource "aws_apigatewayv2_api" "gig_diary_api" {
  name          = "GigDiaryAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.gig_diary_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.gig_diary_function.invoke_arn
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.gig_diary_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.gig_diary_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gig_diary_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gig_diary_api.execution_arn}/*/*"
}

resource "aws_s3_bucket" "react_app" {
  bucket = "gig-diary-react-app-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.react_app]
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.api.invoke_url
}

output "react_app_bucket_name" {
  value = aws_s3_bucket.react_app.bucket
}

output "react_app_website_url" {
  value = aws_s3_bucket_website_configuration.react_app.website_endpoint
}