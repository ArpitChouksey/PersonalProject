from typing import Any, Dict, List

from app.services.terraform_service import (
    TerraformService
)


TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_explain_plan",
        "description": (
            "Analyze the Terraform execution plan and "
            "present infrastructure changes in a "
            "human-readable structured format. "
            "Separate new, modified, replaced and "
            "destroyed resources and show their "
            "important attributes and before/after values."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    }
}


# ============================================================
# Utility Functions
# ============================================================

def clean_value(value: Any) -> Any:
    """
    Convert Terraform JSON values into clean
    JSON-friendly values.
    """

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
# Find Changed Attributes
# ============================================================

def find_changes(
    before: Any,
    after: Any
) -> Dict[str, Dict[str, Any]]:

    changes = {}

    if not isinstance(before, dict):
        before = {}

    if not isinstance(after, dict):
        after = {}

    all_keys = set(
        before.keys()
    ) | set(
        after.keys()
    )

    for key in sorted(all_keys):

        old_value = before.get(key)
        new_value = after.get(key)

        if old_value != new_value:

            changes[key] = {
                "before": clean_value(
                    old_value
                ),
                "after": clean_value(
                    new_value
                )
            }

    return changes


# ============================================================
# Resource Details
# ============================================================

def build_resource(
    resource: Dict[str, Any]
) -> Dict[str, Any]:

    change = resource.get(
        "change",
        {}
    )

    before = clean_value(
        change.get("before")
    )

    after = clean_value(
        change.get("after")
    )

    actions = change.get(
        "actions",
        []
    )

    return {
        "resource": resource.get(
            "address",
            "unknown"
        ),

        "type": resource.get(
            "type",
            "unknown"
        ),

        "name": resource.get(
            "name",
            "unknown"
        ),

        "provider": resource.get(
            "provider_name",
            "unknown"
        ),

        "actions": actions,

        "before": before,

        "after": after,

        "changed_attributes": find_changes(
            before,
            after
        )
    }


# ============================================================
# Classify Resources
# ============================================================

def classify_resources(
    resources: List[Dict[str, Any]]
):

    new_resources = []

    modified_resources = []

    replaced_resources = []

    destroyed_resources = []

    unchanged_resources = []

    for resource in resources:

        resource_data = build_resource(
            resource
        )

        actions = resource_data[
            "actions"
        ]

        if actions == ["create"]:

            new_resources.append(
                resource_data
            )

        elif actions == ["update"]:

            modified_resources.append(
                resource_data
            )

        elif actions == ["delete"]:

            destroyed_resources.append(
                resource_data
            )

        elif (
            "delete" in actions
            and "create" in actions
        ):

            replaced_resources.append(
                resource_data
            )

        elif actions == ["no-op"]:

            unchanged_resources.append(
                resource_data
            )

    return {
        "new": new_resources,
        "modified": modified_resources,
        "replaced": replaced_resources,
        "destroyed": destroyed_resources,
        "unchanged": unchanged_resources
    }


# ============================================================
# Human-Readable Resource Summary
# ============================================================

def resource_summary(
    resource: Dict[str, Any]
) -> Dict[str, Any]:

    after = resource.get(
        "after"
    ) or {}

    before = resource.get(
        "before"
    ) or {}

    # Prefer after values because these represent
    # the desired configuration for create/update.
    source = after if after else before

    summary = {}

    # Common infrastructure fields
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
        "instance_type",
        "public_ip",
        "private_ip",
        "private_dns",
        "bucket",
        "domain_name",
        "tags"
    ]

    for field in important_fields:

        if field in source:

            summary[field] = source[field]

    return summary


# ============================================================
# Build New Resource Table
# ============================================================

def build_new_resource_table(
    resources: List[Dict[str, Any]]
):

    table = []

    for resource in resources:

        table.append({

            "resource":
                resource["resource"],

            "type":
                resource["type"],

            "provider":
                resource["provider"],

            "action":
                "CREATE",

            "details":
                resource_summary(
                    resource
                ),

            "after":
                resource["after"]
        })

    return table


# ============================================================
# Build Existing Resource Table
# ============================================================

def build_existing_resource_table(
    resources: List[Dict[str, Any]]
):

    table = []

    for resource in resources:

        actions = resource[
            "actions"
        ]

        action = ", ".join(
            actions
        ).upper()

        table.append({

            "resource":
                resource["resource"],

            "type":
                resource["type"],

            "provider":
                resource["provider"],

            "action":
                action,

            "before":
                resource["before"],

            "after":
                resource["after"],

            "changed_attributes":
                resource[
                    "changed_attributes"
                ]
        })

    return table


# ============================================================
# Execute
# ============================================================

def execute(
    arguments=None,
    terraform_path=None
):

    if not terraform_path:

        return {
            "status": "error",

            "message": (
                "Terraform path is not set."
            )
        }

    # ========================================================
    # Step 1 - Create Terraform plan
    # ========================================================

    plan_result = (
        TerraformService.plan_json(
            terraform_path
        )
    )

    if plan_result["status"] != "success":

        return {
            "status": "error",

            "message": (
                "Terraform plan failed."
            ),

            "details": plan_result
        }

    # ========================================================
    # Step 2 - Read JSON plan
    # ========================================================

    json_result = (
        TerraformService.show_plan_json(
            terraform_path
        )
    )

    if json_result["status"] != "success":

        return {
            "status": "error",

            "message": (
                "Unable to read Terraform "
                "JSON plan."
            ),

            "details": json_result
        }

    plan = json_result["data"]

    # ========================================================
    # Step 3 - Extract resource changes
    # ========================================================

    resource_changes = plan.get(
        "resource_changes",
        []
    )

    classified = classify_resources(
        resource_changes
    )

    # ========================================================
    # Step 4 - Build tables
    # ========================================================

    new_table = (
        build_new_resource_table(
            classified["new"]
        )
    )

    existing_table = (
        build_existing_resource_table(
            classified["modified"]
            + classified["replaced"]
        )
    )

    destroyed_table = (
        build_existing_resource_table(
            classified["destroyed"]
        )
    )

    # ========================================================
    # Step 5 - Summary
    # ========================================================

    summary = {

        "new":
            len(classified["new"]),

        "modified":
            len(classified["modified"]),

        "replaced":
            len(classified["replaced"]),

        "destroyed":
            len(classified["destroyed"]),

        "total_changes": (
            len(classified["new"])
            + len(classified["modified"])
            + len(classified["replaced"])
            + len(classified["destroyed"])
        )
    }

    # ========================================================
    # Step 6 - Final structured response
    # ========================================================

    return {

        "status": "success",

        "terraform_path":
            terraform_path,

        "summary":
            summary,

        "tables": {

            "new_resources":
                new_table,

            "existing_resources":
                existing_table,

            "destroyed_resources":
                destroyed_table
        },

        # Keep raw structured resources available
        # for future features such as plan records,
        # drift detection and UI rendering.

        "resources": {

            "new":
                classified["new"],

            "modified":
                classified["modified"],

            "replaced":
                classified["replaced"],

            "destroyed":
                classified["destroyed"]
        }
    }
