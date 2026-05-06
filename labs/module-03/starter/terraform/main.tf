# main.tf — Resource definitions
#
# Task 1: Create the following resources:
#
# 1. aws_s3_bucket named "app_data"
#    - bucket name: "${var.project_name}-data-${var.environment}-${var.unique_suffix}"
#    - lifecycle: prevent_destroy = true
#    - tags: Environment = var.environment, ManagedBy = "terraform"
#
# 2. aws_s3_bucket_versioning named "app_data"
#    - bucket: reference the S3 bucket id from resource 1
#    - versioning_configuration: status = "Enabled"
#
# 3. aws_dynamodb_table named "terraform_locks"
#    - name: "${var.project_name}-tf-locks"
#    - billing_mode: "PAY_PER_REQUEST"
#    - hash_key: "LockID"
#    - attribute: name = "LockID", type = "S"

# TODO: Add aws_s3_bucket resource


# TODO: Add aws_s3_bucket_versioning resource


# TODO: Add aws_dynamodb_table resource
