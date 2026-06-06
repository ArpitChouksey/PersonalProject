resource "aws_cloudtrail" "main" {

  name           = var.trail_name
  s3_bucket_name = var.cloudtrail_bucket_name

  is_multi_region_trail         = true
  include_global_service_events = true

  advanced_event_selector {

    name = "Management events selector"

    field_selector {

      field = "eventCategory"

      equals = [
        "Management"
      ]
    }
  }
}
