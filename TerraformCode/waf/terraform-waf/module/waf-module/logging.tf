resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.enable_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = var.log_destination_configs

  # Each entry in var.redacted_fields is one of:
  #   "uri_path", "query_string", "method"
  #   "single_header:<header-name>"
  # NOTE: AWS's redacted_fields schema only supports the four field types
  # above - there is no single_query_argument option here (that field type
  # only exists on match statements like byte_match_statement, not on log
  # redaction).
  dynamic "redacted_fields" {
    for_each = var.redacted_fields
    content {
      dynamic "uri_path" {
        for_each = redacted_fields.value == "uri_path" ? [1] : []
        content {}
      }
      dynamic "query_string" {
        for_each = redacted_fields.value == "query_string" ? [1] : []
        content {}
      }
      dynamic "method" {
        for_each = redacted_fields.value == "method" ? [1] : []
        content {}
      }
      dynamic "single_header" {
        for_each = startswith(redacted_fields.value, "single_header:") ? [trimprefix(redacted_fields.value, "single_header:")] : []
        content {
          name = single_header.value
        }
      }
    }
  }

  dynamic "logging_filter" {
    for_each = length(var.logging_filter.filters) > 0 ? [var.logging_filter] : []
    content {
      default_behavior = logging_filter.value.default_behavior

      dynamic "filter" {
        for_each = logging_filter.value.filters
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
            for_each = filter.value.conditions
            content {
              action_condition {
                action = condition.value.action_condition
              }
            }
          }
        }
      }
    }
  }
}
