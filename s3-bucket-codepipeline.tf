# This bucket is used to store config files, etc. which are used for processing

resource "aws_s3_bucket" "pipeline_resources_bucket" {
  bucket = var.name

  lifecycle {
    prevent_destroy = false
  }

  lifecycle_rule {
    id      = "artifacts"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }

#    logging {
#      target_bucket = var.s3_log_target_bucket
#      target_prefix = "s3/${var.name}/"
#    }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(var.input_tags, {})
}

# Versioning enabled in Pipeline bucket
resource "aws_s3_bucket_versioning" "pipeline_resources_bucket" {
  bucket = aws_s3_bucket.pipeline_resources_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
