from typing import Any, Dict, List


from app.services.terraform_service import (
    TerraformService
)


# ============================================================
# TOOL DEFINITION
# ============================================================

TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_drift",
        "description": (
            "Detect differences between the Terraform "
            "configuration and the currently recorded "
            "Terraform state. Report resources that are "
            "missing, changed, or unexpectedly present."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    }
}


# ============================================================
# CLEAN VALUE
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
# FLATTEN MODULE RESOURCES
# ============================================================

def collect_resources(
    module: Dict[str, Any]
) -> List[Dict[str, Any]]:

    resources = []

    for resource in module.get(
        "resources",
        []
    ):

        resources.append(resource)

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
# RESOURCE MAP
# ============================================================

def build_resource_map(
    resources: List[Dict[str, Any]]
):

    resource_map = {}

    for resource in resources:

        address = resource.get(
            "address"
        )

        if not address:
            continue

        resource_map[address] = resource

    return resource_map


# ============================================================
# COMPARE VALUES
# ============================================================

def compare_values(
    expected: Any,
    actual: Any,
    path: str = ""
):

    differences = []

    # --------------------------------------------------------
    # Dictionaries
    # --------------------------------------------------------

    if isinstance(expected, dict):

        if not isinstance(actual, dict):

            differences.append({
                "attribute": path,
                "expected": clean_value(
                    expected
                ),
                "actual": clean_value(
                    actual
                )
            })

            return differences

        all_keys = (
            set(expected.keys())
            | set(actual.keys())
        )

        for key in sorted(all_keys):

            child_path = (
                f"{path}.{key}"
                if path
                else key
            )

            expected_value = (
                expected.get(key)
            )

            actual_value = (
                actual.get(key)
            )

            if (
                expected_value is None
                and key not in expected
            ):
                differences.append({
                    "attribute": child_path,
                    "expected": None,
                    "actual": clean_value(
                        actual_value
                    )
                })

                continue

            if (
                actual_value is None
                and key not in actual
            ):
                differences.append({
                    "attribute": child_path,
                    "expected": clean_value(
                        expected_value
                    ),
                    "actual": None
                })

                continue

            differences.extend(
                compare_values(
                    expected_value,
                    actual_value,
                    child_path
                )
            )

        return differences

    # --------------------------------------------------------
    # Lists
    # --------------------------------------------------------

    if isinstance(expected, list):

        if not isinstance(actual, list):

            differences.append({
                "attribute": path,
                "expected": clean_value(
                    expected
                ),
                "actual": clean_value(
                    actual
                )
            })

            return differences

        if expected != actual:

            differences.append({
                "attribute": path,
                "expected": clean_value(
                    expected
                ),
                "actual": clean_value(
                    actual
                )
            })

        return differences

    # --------------------------------------------------------
    # Primitive values
    # --------------------------------------------------------

    if expected != actual:

        differences.append({
            "attribute": path,
            "expected": clean_value(
                expected
            ),
            "actual": clean_value(
                actual
            )
        })

    return differences


# ============================================================
# IMPORTANT FIELDS
# ============================================================

IMPORTANT_FIELDS = [

    "id",
    "arn",
    "name",
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

    "instance_type",

    "tags",
]


# ============================================================
# FILTER RESOURCE VALUES
# ============================================================

def important_values(
    values: Dict[str, Any]
):

    if not values:
        return {}

    result = {}

    for field in IMPORTANT_FIELDS:

        if field in values:

            value = values[field]

            if value is not None:

                result[field] = (
                    clean_value(value)
                )

    return result


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
    # STEP 1
    # Generate Terraform plan
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
                "Unable to generate Terraform plan."
            ),

            "details": plan_result
        }

    # ========================================================
    # STEP 2
    # Read Terraform state
    # ========================================================

    state_result = (
        TerraformService.state_json(
            terraform_path
        )
    )

    if state_result["status"] != "success":

        return {
            "status": "error",

            "message": (
                "Unable to read Terraform state."
            ),

            "details": state_result
        }

    # ========================================================
    # STEP 3
    # Get plan JSON
    # ========================================================

    plan = plan_result.get(
        "data",
        {}
    )

    # ========================================================
    # STEP 4
    # Get state JSON
    # ========================================================

    state = state_result.get(
        "data",
        {}
    )

    # ========================================================
    # STEP 5
    # Current state resources
    # ========================================================

    root_module = (
        state
        .get("values", {})
        .get("root_module", {})
    )

    state_resources = collect_resources(
        root_module
    )

    state_map = build_resource_map(
        state_resources
    )

    # ========================================================
    # STEP 6
    # Terraform plan resource changes
    # ========================================================

    plan_resources = plan.get(
        "resource_changes",
        []
    )

    drifted_resources = []

    missing_resources = []

    extra_resources = []

    planned_changes = []

    # ========================================================
    # STEP 7
    # Inspect Terraform plan
    # ========================================================

    for resource in plan_resources:

        address = resource.get(
            "address"
        )

        change = resource.get(
            "change",
            {}
        )

        actions = change.get(
            "actions",
            []
        )

        before = change.get(
            "before"
        )

        after = change.get(
            "after"
        )

        # ----------------------------------------------------
        # Terraform wants to create resource
        # ----------------------------------------------------

        if actions == ["create"]:

            missing_resources.append({

                "resource":
                    address,

                "type":
                    resource.get(
                        "type"
                    ),

                "action":
                    "CREATE",

                "message":
                    (
                        "Resource exists in configuration "
                        "but is not currently recorded "
                        "in Terraform state."
                    )
            })

            continue

        # ----------------------------------------------------
        # Terraform wants to destroy resource
        # ----------------------------------------------------

        if actions == ["delete"]:

            extra_resources.append({

                "resource":
                    address,

                "type":
                    resource.get(
                        "type"
                    ),

                "action":
                    "DESTROY",

                "message":
                    (
                        "Resource exists in Terraform state "
                        "but Terraform configuration no "
                        "longer wants this resource."
                    )
            })

            continue

        # ----------------------------------------------------
        # Update
        # ----------------------------------------------------

        if actions == ["update"]:

            planned_changes.append({

                "resource":
                    address,

                "type":
                    resource.get(
                        "type"
                    ),

                "action":
                    "UPDATE",

                "before":
                    clean_value(before),

                "after":
                    clean_value(after)
            })

    # ========================================================
    # STEP 8
    # Build drift report
    # ========================================================

    for change in planned_changes:

        address = change[
            "resource"
        ]

        state_resource = state_map.get(
            address
        )

        if not state_resource:

            continue

        actual = state_resource.get(
            "values",
            {}
        )

        expected = change.get(
            "after",
            {}
        )

        expected = important_values(
            expected
        )

        actual = important_values(
            actual
        )

        differences = compare_values(
            expected,
            actual
        )

        if differences:

            drifted_resources.append({

                "resource":
                    address,

                "type":
                    change["type"],

                "action":
                    "DRIFT",

                "differences":
                    differences
            })

    # ========================================================
    # STEP 9
    # Summary
    # ========================================================

    summary = {

        "drift_detected":
            len(drifted_resources) > 0,

        "drifted_resources":
            len(drifted_resources),

        "missing_resources":
            len(missing_resources),

        "extra_resources":
            len(extra_resources),

        "planned_updates":
            len(planned_changes)
    }

    # ========================================================
    # STEP 10
    # Final response
    # ========================================================

    return {

        "status": "success",

        "terraform_path":
            terraform_path,

        "summary":
            summary,

        "drifted_resources":
            drifted_resources,

        "missing_resources":
            missing_resources,

        "extra_resources":
            extra_resources,

        "planned_changes":
            planned_changes
    }
