resource "aws_cloudfront_distribution" "cdn" {


  web_acl_id          = var.web_acl_id
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  comment = "CloudFront CDN for S3 static website"

  origin {
    domain_name = "${var.bucket_name}.s3.ap-south-1.amazonaws.com"

    #origin_id = "${var.bucket_name}-origin"
    origin_id = "${var.bucket_name}.s3.ap-south-1.amazonaws.com-mpduenpf3yt"

    origin_access_control_id = var.origin_access_control_id
  }

  default_cache_behavior {

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    #target_origin_id = "arpit-static-site-demo-001-origin"

    target_origin_id = "${var.bucket_name}.s3.ap-south-1.amazonaws.com-mpduenpf3yt"

    viewer_protocol_policy = "redirect-to-https"

    compress = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "arpit-static-site-cdn"
  }
}
