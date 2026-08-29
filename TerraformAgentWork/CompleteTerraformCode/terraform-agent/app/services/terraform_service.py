import json
import subprocess


class TerraformService:

    @staticmethod
    def run_command(
        command: list[str],
        terraform_path: str
    ):
        """
        Execute a Terraform CLI command.
        """

        try:
            result = subprocess.run(
                command,
                cwd=terraform_path,
                capture_output=True,
                text=True
            )

            return {
                "status": (
                    "success"
                    if result.returncode == 0
                    else "error"
                ),
                "return_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }

        except Exception as exc:
            return {
                "status": "error",
                "message": str(exc)
            }

    # ---------------------------------------------------------
    # TERRAFORM INIT
    # ---------------------------------------------------------

    @staticmethod
    def init(terraform_path: str):
        """
        Run terraform init.
        """

        return TerraformService.run_command(
            [
                "terraform",
                "init"
            ],
            terraform_path
        )

    # ---------------------------------------------------------
    # TERRAFORM VALIDATE
    # ---------------------------------------------------------

    @staticmethod
    def validate(terraform_path: str):
        """
        Run terraform validate.
        """

        return TerraformService.run_command(
            [
                "terraform",
                "validate"
            ],
            terraform_path
        )

    # ---------------------------------------------------------
    # TERRAFORM PLAN
    # ---------------------------------------------------------

    @staticmethod
    def plan(terraform_path: str):
        """
        Run terraform plan and save the plan
        to a file named tfplan.
        """

        return TerraformService.run_command(
            [
                "terraform",
                "plan",
                "-out=tfplan"
            ],
            terraform_path
        )

    # ---------------------------------------------------------
    # TERRAFORM PLAN JSON
    # ---------------------------------------------------------

    @staticmethod
    def plan_json(terraform_path: str):
        """
        Generate a Terraform plan and return it as JSON.
        """

        try:

            plan_result = subprocess.run(
                [
                    "terraform",
                    "plan",
                    "-out=tfplan"
                ],
                cwd=terraform_path,
                capture_output=True,
                text=True
            )

            if plan_result.returncode != 0:
                return {
                    "status": "error",
                    "return_code": plan_result.returncode,
                    "stdout": plan_result.stdout,
                    "stderr": plan_result.stderr
                }

            show_result = subprocess.run(
                [
                    "terraform",
                    "show",
                    "-json",
                    "tfplan"
                ],
                cwd=terraform_path,
                capture_output=True,
                text=True
            )

            if show_result.returncode != 0:
                return {
                    "status": "error",
                    "return_code": show_result.returncode,
                    "stdout": show_result.stdout,
                    "stderr": show_result.stderr
                }

            try:

                data = json.loads(
                    show_result.stdout
                )

            except json.JSONDecodeError as exc:

                return {
                    "status": "error",
                    "message": (
                        "Terraform returned invalid JSON."
                    ),
                    "error": str(exc),
                    "stdout": show_result.stdout
                }

            return {
                "status": "success",
                "return_code": 0,
                "data": data
            }

        except Exception as exc:

            return {
                "status": "error",
                "message": str(exc)
            }

    # ---------------------------------------------------------
    # SHOW SAVED PLAN AS JSON
    # ---------------------------------------------------------

    @staticmethod
    def show_plan_json(terraform_path: str):
        """
        Convert the existing tfplan file into JSON.

        This method is used by:
        - terraform_explain_plan
        - terraform_drift
        """

        try:

            result = subprocess.run(
                [
                    "terraform",
                    "show",
                    "-json",
                    "tfplan"
                ],
                cwd=terraform_path,
                capture_output=True,
                text=True
            )

            if result.returncode != 0:

                return {
                    "status": "error",
                    "return_code": result.returncode,
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }

            try:

                data = json.loads(
                    result.stdout
                )

            except json.JSONDecodeError as exc:

                return {
                    "status": "error",
                    "message": (
                        "Terraform returned invalid JSON."
                    ),
                    "error": str(exc),
                    "stdout": result.stdout
                }

            return {
                "status": "success",
                "return_code": result.returncode,
                "data": data
            }

        except Exception as exc:

            return {
                "status": "error",
                "message": str(exc)
            }

    # ---------------------------------------------------------
    # TERRAFORM STATE JSON
    # ---------------------------------------------------------

    @staticmethod
    def state_json(terraform_path: str):
        """
        Return the current Terraform state as JSON.
        """

        try:

            result = subprocess.run(
                [
                    "terraform",
                    "show",
                    "-json"
                ],
                cwd=terraform_path,
                capture_output=True,
                text=True
            )

            if result.returncode != 0:

                return {
                    "status": "error",
                    "return_code": result.returncode,
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }

            try:

                data = json.loads(
                    result.stdout
                )

            except json.JSONDecodeError as exc:

                return {
                    "status": "error",
                    "message": (
                        "Terraform returned invalid JSON."
                    ),
                    "error": str(exc),
                    "stdout": result.stdout
                }

            return {
                "status": "success",
                "return_code": result.returncode,
                "data": data
            }

        except Exception as exc:

            return {
                "status": "error",
                "message": str(exc)
            }

    # ---------------------------------------------------------
    # TERRAFORM REFRESH STATE
    # ---------------------------------------------------------

    @staticmethod
    def refresh_state(terraform_path: str):
        """
        Refresh Terraform state against real infrastructure.
        """

        return TerraformService.run_command(
            [
                "terraform",
                "refresh"
            ],
            terraform_path
        )
