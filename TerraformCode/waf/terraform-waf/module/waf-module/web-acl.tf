locals {
  geo_match_rule_entries = [
    for r in var.geo_match_rules : {
      rule_type = "geo"
      name      = r.name
      priority  = r.priority
      action    = r.action
      geo       = r
    }
  ]
}

resource "aws_wafv2_web_acl" "this" {
  name        = local.resource_name
  description = var.description
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = local.all_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # ---------------- action / override_action ----------------
      dynamic "override_action" {
        for_each = rule.value.rule_type == "managed" ? [1] : []
        content {
          dynamic "none" {
            for_each = rule.value.override_action == "none" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = rule.value.override_action == "count" ? [1] : []
            content {}
          }
        }
      }

      dynamic "action" {
        for_each = rule.value.rule_type != "managed" ? [1] : []
        content {
          dynamic "allow" {
            for_each = rule.value.action == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = rule.value.action == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = rule.value.action == "count" ? [1] : []
            content {}
          }
        }
      }

      # ---------------- statement ----------------
      statement {
        # ----- AWS Managed Rule Group -----
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.rule_type == "managed" ? [1] : []
          content {
            name        = rule.value.managed.managed_rule_group
            vendor_name = rule.value.managed.vendor_name
            version     = rule.value.managed.version != "" ? rule.value.managed.version : null

            dynamic "rule_action_override" {
              for_each = rule.value.managed.excluded_rules
              content {
                name = rule_action_override.value
                action_to_use {
                  count {}
                }
              }
            }
          }
        }

        # ----- Rate-based -----
        dynamic "rate_based_statement" {
          for_each = rule.value.rule_type == "rate" ? [1] : []
          content {
            limit              = rule.value.rate.limit
            aggregate_key_type = rule.value.rate.aggregate_key_type

            dynamic "forwarded_ip_config" {
              for_each = rule.value.rate.aggregate_key_type == "FORWARDED_IP" ? [1] : []
              content {
                header_name       = rule.value.rate.forwarded_ip_header
                fallback_behavior = "MATCH"
              }
            }
          }
        }

        # ----- IP set reference -----
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.rule_type == "ip_set" ? [1] : []
          content {
            arn = rule.value.ip_set_arn
          }
        }

        # ----- Geo match -----
        dynamic "geo_match_statement" {
          for_each = rule.value.rule_type == "geo" ? [1] : []
          content {
            country_codes = rule.value.geo.country_codes
          }
        }

        # ----- Regex pattern set reference -----
        dynamic "regex_pattern_set_reference_statement" {
          for_each = rule.value.rule_type == "regex" ? [1] : []
          content {
            arn = rule.value.regex_pattern_set_arn

            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.field_to_match_type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = rule.value.field_to_match_type == "query_string" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = rule.value.field_to_match_type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = rule.value.field_to_match_type == "body" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = rule.value.field_to_match_type == "single_header" ? [1] : []
                content {
                  name = rule.value.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = rule.value.text_transformation_type
            }
          }
        }

        # ----- Custom: byte match -----
        dynamic "byte_match_statement" {
          for_each = rule.value.rule_type == "custom" && rule.value.custom.statement_type == "byte_match" ? [1] : []
          content {
            search_string         = rule.value.custom.search_string
            positional_constraint = rule.value.custom.positional_constraint

            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.custom.field_to_match_type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = rule.value.custom.field_to_match_type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = rule.value.custom.field_to_match_type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = rule.value.custom.field_to_match_type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = rule.value.custom.field_to_match_type == "body" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = rule.value.custom.field_to_match_type == "single_header" ? [1] : []
                content {
                  name = rule.value.custom.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = rule.value.custom.text_transformation_type
            }
          }
        }

        # ----- Custom: size constraint -----
        dynamic "size_constraint_statement" {
          for_each = rule.value.rule_type == "custom" && rule.value.custom.statement_type == "size_constraint" ? [1] : []
          content {
            comparison_operator = rule.value.custom.comparison_operator
            size                = rule.value.custom.size

            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.custom.field_to_match_type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = rule.value.custom.field_to_match_type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = rule.value.custom.field_to_match_type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = rule.value.custom.field_to_match_type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = rule.value.custom.field_to_match_type == "body" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = rule.value.custom.field_to_match_type == "single_header" ? [1] : []
                content {
                  name = rule.value.custom.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = rule.value.custom.text_transformation_type
            }
          }
        }

        # ----- Custom: SQLi match -----
        dynamic "sqli_match_statement" {
          for_each = rule.value.rule_type == "custom" && rule.value.custom.statement_type == "sqli_match" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.custom.field_to_match_type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = rule.value.custom.field_to_match_type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = rule.value.custom.field_to_match_type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = rule.value.custom.field_to_match_type == "body" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = rule.value.custom.field_to_match_type == "single_header" ? [1] : []
                content {
                  name = rule.value.custom.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = rule.value.custom.text_transformation_type
            }
          }
        }

        # ----- Custom: XSS match -----
        dynamic "xss_match_statement" {
          for_each = rule.value.rule_type == "custom" && rule.value.custom.statement_type == "xss_match" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.custom.field_to_match_type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = rule.value.custom.field_to_match_type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = rule.value.custom.field_to_match_type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = rule.value.custom.field_to_match_type == "body" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = rule.value.custom.field_to_match_type == "single_header" ? [1] : []
                content {
                  name = rule.value.custom.header_name
                }
              }
            }

            text_transformation {
              priority = 0
              type     = rule.value.custom.text_transformation_type
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        sampled_requests_enabled   = var.sampled_requests_enabled
        metric_name                = "${local.metric_name}${rule.value.name}"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    sampled_requests_enabled   = var.sampled_requests_enabled
    metric_name                = local.metric_name
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
