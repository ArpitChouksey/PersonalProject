###############################################################
# REST API Resource Tree
#
# Splits each route path into its full ancestor chain so nested
# resources are created automatically, e.g.:
#
#   /employees/{id}/address
#
# expands into three resource nodes:
#
#   /employees
#   /employees/{id}
#   /employees/{id}/address
#
# without any manual resource configuration.
###############################################################

locals {

  #############################################################
  # Distinct (api_key, path) pairs referenced by routes
  #############################################################

  rest_route_paths = distinct([

    for route in local.rest_routes : {

      api_key = route.api_key

      path    = route.path

    }

  ])

  #############################################################
  # Path segments per (api_key, path)
  #############################################################

  rest_path_segments = {

    for item in local.rest_route_paths :

    "${item.api_key}|${item.path}" => compact(split("/", item.path))

  }

  #############################################################
  # Expand every path into its full ancestor chain
  #############################################################

  rest_resource_nodes = distinct(flatten([

    for key, segments in local.rest_path_segments : [

      for i in range(1, length(segments) + 1) : {

        api_key = split("|", key)[0]

        path = "/${join("/", slice(segments, 0, i))}"

        parent_path = i == 1 ? "/" : "/${join("/", slice(segments, 0, i - 1))}"

        path_part = segments[i - 1]

        depth = i

      }

    ]

  ]))

  #############################################################
  # Resource tree keyed by api_key + full path
  #############################################################

  rest_resources = {

    for node in local.rest_resource_nodes :

    "${node.api_key}-${node.path}" => node

  }

  #############################################################
  # Per-depth maps
  #
  # A single self-referencing for_each (this resource's parent_id
  # looking up another instance of itself by a computed key)
  # causes Terraform to report a dependency cycle across every
  # node, even though the tree itself is acyclic -- Terraform's
  # graph builder can't always prove per-instance safety for a
  # resource that conditionally references its own resource type.
  #
  # The reliable fix is to split resource creation into one
  # resource block per depth level, where depth N only ever
  # references depth N-1 (a different resource address each
  # time), never itself. 6 levels comfortably covers realistic
  # nesting (e.g. /a/{b}/c/{d}/e/{f} is already 6 segments deep).
  #############################################################

  rest_resources_d1 = { for k, v in local.rest_resources : k => v if v.depth == 1 }
  rest_resources_d2 = { for k, v in local.rest_resources : k => v if v.depth == 2 }
  rest_resources_d3 = { for k, v in local.rest_resources : k => v if v.depth == 3 }
  rest_resources_d4 = { for k, v in local.rest_resources : k => v if v.depth == 4 }
  rest_resources_d5 = { for k, v in local.rest_resources : k => v if v.depth == 5 }
  rest_resources_d6 = { for k, v in local.rest_resources : k => v if v.depth == 6 }

}
