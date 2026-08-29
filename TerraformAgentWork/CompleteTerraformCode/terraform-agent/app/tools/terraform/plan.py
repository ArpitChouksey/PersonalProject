from app.services.terraform_service import TerraformService


TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_plan",
        "description": (
            "Run Terraform plan and show the "
            "planned infrastructure changes."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": []
        }
    }
}


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

    return TerraformService.plan(
        terraform_path
    )
