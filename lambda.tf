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

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gig_diary_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gig_diary_api.execution_arn}/*/*"
}