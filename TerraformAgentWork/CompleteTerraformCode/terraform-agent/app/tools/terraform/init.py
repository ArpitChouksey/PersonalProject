from app.services.terraform_service import TerraformService


TOOL_DEFINITION = {
    "type": "function",
    "function": {
        "name": "terraform_init",
        "description": (
            "Initialize Terraform in the current "
            "Terraform working directory."
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

    return TerraformService.init(
        terraform_path
    )
