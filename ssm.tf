resource "aws_ssm_parameter" "gig_diary_google_config" {
  name  = "GigDiaryGoogleConfig"
  type  = "SecureString"
  value = "."
  
  lifecycle {
    ignore_changes = [value]
  }
}