from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def crashloop_pods(namespace: str = "default"):
    """
    Find pods with containers currently showing CrashLoopBackOff.
    """

    result = run_kubectl(
        [
            "get",
            "pods",
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    lines = result["stdout"].splitlines()

    if not lines:
        return {
            "status": "success",
            "resource": "crashloop-pods",
            "output": "No pods found."
        }

    matches = [
        line
        for line in lines
        if "CrashLoopBackOff" in line
    ]

    return {
        "status": "success",
        "resource": "crashloop-pods",
        "output": "\n".join(matches)
        if matches
        else "No CrashLoopBackOff pods found."
    }
