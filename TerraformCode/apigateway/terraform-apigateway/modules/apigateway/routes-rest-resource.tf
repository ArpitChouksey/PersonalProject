###############################################################
# REST API Resources
#
# Creates the full parent/child resource tree for every REST
# API from the normalized paths in rest-resources-locals.tf.
#
# Split into one resource block per depth level (see the comment
# in rest-resources-locals.tf for why): each level's parent_id
# references only the PREVIOUS level's resource block, never its
# own -- a self-referencing for_each (this resource looking up
# another instance of itself) causes Terraform to report a
# dependency cycle across the whole tree, even when the tree
# itself is a valid acyclic structure.
###############################################################

###############################################################
# Depth 1 (e.g. /employees) -- parent is always the API root
###############################################################

resource "aws_api_gateway_resource" "rest_d1" {

  for_each = local.rest_resources_d1

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_rest_api.rest[each.value.api_key].root_resource_id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Depth 2 (e.g. /employees/{id}) -- parent is a depth-1 resource
###############################################################

resource "aws_api_gateway_resource" "rest_d2" {

  for_each = local.rest_resources_d2

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_resource.rest_d1["${each.value.api_key}-${each.value.parent_path}"].id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Depth 3 (e.g. /employees/{id}/address) -- parent is depth-2
###############################################################

resource "aws_api_gateway_resource" "rest_d3" {

  for_each = local.rest_resources_d3

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_resource.rest_d2["${each.value.api_key}-${each.value.parent_path}"].id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Depth 4 -- parent is depth-3
###############################################################

resource "aws_api_gateway_resource" "rest_d4" {

  for_each = local.rest_resources_d4

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_resource.rest_d3["${each.value.api_key}-${each.value.parent_path}"].id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Depth 5 -- parent is depth-4
###############################################################

resource "aws_api_gateway_resource" "rest_d5" {

  for_each = local.rest_resources_d5

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_resource.rest_d4["${each.value.api_key}-${each.value.parent_path}"].id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Depth 6 -- parent is depth-5 (deepest level currently supported)
###############################################################

resource "aws_api_gateway_resource" "rest_d6" {

  for_each = local.rest_resources_d6

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  parent_id = aws_api_gateway_resource.rest_d5["${each.value.api_key}-${each.value.parent_path}"].id

  path_part = each.value.path_part

  lifecycle {
    create_before_destroy = true
  }

}

###############################################################
# Combined lookup -- every resource ID regardless of depth,
# keyed exactly like local.rest_resources ("${api_key}-${path}").
# Everything downstream (methods, integrations, responses) reads
# resource IDs through this map instead of referencing
# aws_api_gateway_resource.rest_dN directly.
###############################################################

locals {

  rest_resource_ids = merge(
    { for k, v in aws_api_gateway_resource.rest_d1 : k => v.id },
    { for k, v in aws_api_gateway_resource.rest_d2 : k => v.id },
    { for k, v in aws_api_gateway_resource.rest_d3 : k => v.id },
    { for k, v in aws_api_gateway_resource.rest_d4 : k => v.id },
    { for k, v in aws_api_gateway_resource.rest_d5 : k => v.id },
    { for k, v in aws_api_gateway_resource.rest_d6 : k => v.id },
  )

}
