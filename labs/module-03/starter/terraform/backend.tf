# backend.tf — Remote state configuration
#
# Task 2: After creating the S3 bucket and DynamoDB table (Task 1),
# uncomment the backend block below and run:
#
#   terraform init -migrate-state
#
# This migrates your local state file to the remote S3 backend.

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE-WITH-YOUR-BUCKET-NAME"
#     key            = "dev/terraform.tfstate"
#     region         = "eu-west-1"
#     encrypt        = true
#     dynamodb_table = "REPLACE-WITH-YOUR-TABLE-NAME"
#   }
# }
