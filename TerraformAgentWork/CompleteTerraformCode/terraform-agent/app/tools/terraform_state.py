from typing import Any, Dict, List

from app.services.terraform_service import TerraformService


# ============================================================
# TOOL DEFINITION
# ============================================================

TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_state",
        "description": (
            "Read the current Terraform state and provide a "
            "human-readable summary of deployed resources, "
            "including resource IDs, ARNs, IP addresses, "
            "VPCs, subnets, availability zones, regions, "
            "and other useful infrastructure attributes."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    }
}


# ============================================================
# SAFE VALUE CLEANER
# ============================================================

def clean_value(value: Any) -> Any:

    if value is None:
        return None

    if isinstance(value, dict):

        return {
            key: clean_value(val)
            for key, val in value.items()
        }

    if isinstance(value, list):

        return [
            clean_value(item)
            for item in value
        ]

    return value


# ============================================================
# RESOURCE DETAILS
# ============================================================

def extract_resource_details(
    resource: Dict[str, Any]
) -> Dict[str, Any]:

    attributes = resource.get(
        "values",
        {}
    ) or {}

    attributes = clean_value(
        attributes
    )

    # Important fields we want to expose
    # in the human-readable response.

    important_fields = [
        "id",
        "arn",
        "name",
        "description",
        "region",
        "cidr_block",
        "availability_zone",
        "availability_zone_id",
        "vpc_id",
        "subnet_id",
        "route_table_id",
        "gateway_id",
        "internet_gateway_id",
        "public_ip",
        "private_ip",
        "private_dns",
        "dns_name",
        "domain_name",
        "instance_type",
        "security_group_id",
        "security_groups",
        "tags"
    ]

    details = {}

    for field in important_fields:

        if field in attributes:

            value = attributes[field]

            # Ignore completely empty values.
            if value is not None:
                details[field] = value

    return details


# ============================================================
# RESOURCE TABLE
# ============================================================

def build_resource_table(
    resources: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:

    table = []

    for resource in resources:

        address = resource.get(
            "address",
            "unknown"
        )

        resource_type = resource.get(
            "type",
            "unknown"
        )

        provider = resource.get(
            "provider_name",
            "unknown"
        )

        details = extract_resource_details(
            resource
        )

        table.append({

            "resource":
                address,

            "type":
                resource_type,

            "provider":
                provider,

            "id":
                details.get("id"),

            "arn":
                details.get("arn"),

            "region":
                details.get("region"),

            "availability_zone":
                details.get(
                    "availability_zone"
                ),

            "cidr_block":
                details.get(
                    "cidr_block"
                ),

            "vpc_id":
                details.get(
                    "vpc_id"
                ),

            "subnet_id":
                details.get(
                    "subnet_id"
                ),

            "public_ip":
                details.get(
                    "public_ip"
                ),

            "private_ip":
                details.get(
                    "private_ip"
                ),

            "tags":
                details.get(
                    "tags"
                ),

            "details":
                details
        })

    return table


# ============================================================
# FLATTEN MODULE RESOURCES
# ============================================================

def collect_resources(
    module: Dict[str, Any]
) -> List[Dict[str, Any]]:

    resources = []

    # Resources belonging to this module

    for resource in module.get(
        "resources",
        []
    ):

        resources.append(
            resource
        )

    # Child modules

    for child_module in module.get(
        "child_modules",
        []
    ):

        resources.extend(
            collect_resources(
                child_module
            )
        )

    return resources


# ============================================================
# EXECUTE
# ============================================================

def execute(
    arguments=None,
    terraform_path=None
):

    if not terraform_path:

        return {
            "status": "error",

            "message": (
                "Terraform path is not set. "
                "Please provide a Terraform project path."
            )
        }

    # ========================================================
    # Step 1
    # Read Terraform state as JSON
    # ========================================================

    result = (
        TerraformService.state_json(
            terraform_path
        )
    )

    if result["status"] != "success":

        return {
            "status": "error",

            "message": (
                "Unable to read Terraform state."
            ),

            "details": result
        }

    state = result["data"]

    # ========================================================
    # Step 2
    # Collect resources
    # ========================================================

    root_module = state.get(
        "values",
        {}
    ).get(
        "root_module",
        {}
    )

    resources = collect_resources(
        root_module
    )

    # ========================================================
    # Step 3
    # Build table
    # ========================================================

    resource_table = (
        build_resource_table(
            resources
        )
    )

    # ========================================================
    # Step 4
    # Summary
    # ========================================================

    summary = {

        "total_resources":
            len(resources),

        "resources_with_public_ip":
            sum(
                1
                for resource in resource_table
                if resource.get("public_ip")
            ),

        "resources_with_private_ip":
            sum(
                1
                for resource in resource_table
                if resource.get("private_ip")
            ),

        "resources_with_arn":
            sum(
                1
                for resource in resource_table
                if resource.get("arn")
            )
    }

    # ========================================================
    # Step 5
    # Return
    # ========================================================

    return {

        "status": "success",

        "terraform_path":
            terraform_path,

        "summary":
            summary,

        "resources":
            resource_table
    }
