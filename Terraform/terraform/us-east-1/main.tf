module "s3" {
  source = "../modules/s3"

  bucket_name = var.bucket_name
  environment = var.environment
}

module "cloudfront" {
  source = "../modules/cloudfront"

  bucket_name              = module.s3.bucket_name
  website_endpoint         = module.s3.website_endpoint
  origin_access_control_id = "ECCLBQDMNVIMS"
  web_acl_id = "arn:aws:wafv2:us-east-1:211811255273:global/webacl/CreatedByCloudFront-8ec41223/4ebb21c0-2679-4b21-9497-8062c391437c"
}

