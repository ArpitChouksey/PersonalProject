from app.services.terraform_service import TerraformService


TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_validate",
        "description": (
            "Validate Terraform configuration "
            "in the current Terraform directory."
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

    return TerraformService.validate(
        terraform_path
    )
