output "codepipeline_resources_bucket_arn" {
  description = "outputs the full arn of the bucket created"
  value       = aws_s3_bucket.pipeline_resources_bucket.arn
}