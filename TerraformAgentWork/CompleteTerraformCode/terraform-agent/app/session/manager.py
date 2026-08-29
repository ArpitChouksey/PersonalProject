import uuid
from typing import Dict, Optional


class SessionManager:

    def __init__(self):

        self.sessions: Dict[str, Dict] = {}

        # Automatically create the first session
        self.default_session_id = (
            self.create_session()
        )

    # ========================================================
    # Create Session
    # ========================================================

    def create_session(self) -> str:

        session_id = str(
            uuid.uuid4()
        )

        self.sessions[session_id] = {
            "terraform_path": None
        }

        return session_id

    # ========================================================
    # Get Default Session
    # ========================================================

    def get_default_session_id(
        self
    ) -> str:

        return self.default_session_id

    # ========================================================
    # Get Terraform Path
    # ========================================================

    def get_terraform_path(
        self,
        session_id: str
    ) -> Optional[str]:

        session = self.sessions.get(
            session_id
        )

        if not session:
            return None

        return session.get(
            "terraform_path"
        )

    # ========================================================
    # Set Terraform Path
    # ========================================================

    def set_terraform_path(
        self,
        session_id: str,
        terraform_path: str
    ):

        if session_id not in self.sessions:

            self.sessions[session_id] = {
                "terraform_path": None
            }

        self.sessions[session_id][
            "terraform_path"
        ] = terraform_path

    # ========================================================
    # Clear Session
    # ========================================================

    def clear_session(
        self,
        session_id: str
    ):

        self.sessions.pop(
            session_id,
            None
        )
