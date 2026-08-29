# Adding a New Tool to the Terraform Agent

This document explains how a developer can extend the Terraform Agent by adding a new tool without breaking the existing architecture.

The project follows this flow:

```text
React UI
   |
   v
FastAPI
   |
   v
Terraform Agent
   |
   v
Tool Registry
   |
   v
Terraform Tool
   |
   v
TerraformService
   |
   v
Terraform CLI
```

The important principle is:

> **A new capability should be added as a tool, registered in the tool registry, and connected to the agent. Do not put Terraform command logic directly inside the API/UI.**

---

# 1. Current Project Structure

The backend follows this logical structure:

```text
terraform-agent/
│
├── app/
│   │
│   ├── main.py
│   │
│   ├── agent/
│   │   └── agent.py
│   │
│   ├── services/
│   │   └── terraform_service.py
│   │
│   └── tools/
│       │
│       ├── registry.py
│       │
│       └── terraform/
│           ├── init.py
│           ├── validate.py
│           ├── plan.py
│           ├── explain_plan.py
│           ├── state.py
│           └── drift.py
│
├── requirements.txt
└── Dockerfile
```

The frontend is separate:

```text
terraform-ui/
│
├── src/
│   ├── App.jsx
│   ├── components/
│   └── services/
│       └── api.js
│
├── package.json
├── Dockerfile
└── nginx.conf
```

---

# 2. What Happens When a User Requests a Tool?

For example, the user says:

```text
terraform validate
```

The request travels through:

```text
User
 |
 v
React
 |
 | POST /agent/chat
 v
FastAPI
 |
 v
TerraformAgent
 |
 | identify intent
 v
Tool Registry
 |
 | terraform_validate
 v
validate.py
 |
 v
TerraformService.validate()
 |
 v
terraform validate
 |
 v
Terraform workspace
 |
 v
Result
 |
 v
React UI
```

If we add a new tool such as:

```text
terraform output
```

the same architecture should be followed:

```text
User
 |
 v
Agent
 |
 v
terraform_output
 |
 v
output.py
 |
 v
TerraformService.output()
 |
 v
terraform output
```

---

# 3. Before Adding a Tool

First decide what the new capability should do.

Example:

```text
New tool:
terraform output
```

Purpose:

```text
Read Terraform output values from the selected workspace.
```

Define:

```text
Tool name
Tool purpose
Required arguments
Terraform command
Expected response
Error handling
```

Example:

| Property | Value |
|---|---|
| Tool name | `terraform_output` |
| Purpose | Read Terraform outputs |
| Terraform command | `terraform output -json` |
| Input | Terraform workspace |
| Output | JSON |
| Layer | Terraform tool |
| Service method | `TerraformService.output()` |

---

# 4. Step 1 — Add the Service Method

File:

```text
app/services/terraform_service.py
```

The service contains the low-level Terraform command execution.

Add a method such as:

```python
@staticmethod
def output(terraform_path: str):
    try:
        result = subprocess.run(
            [
                "terraform",
                "output",
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
            data = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            return {
                "status": "error",
                "message": "Terraform returned invalid JSON.",
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
```

The important part is:

```python
cwd=terraform_path
```

The tool uses the workspace supplied at runtime.

Do **not** add a developer-specific host path such as:

```python
cwd="/Users/arpitchouksey/..."
```

---

# 5. Step 2 — Create the Tool File

Create:

```text
app/tools/terraform/output.py
```

Example:

```python
from app.services.terraform_service import TerraformService


def execute(terraform_path: str):
    return TerraformService.output(terraform_path)
```

The tool layer should stay small.

Its job is to expose the capability to the agent/tool registry.

The architecture is:

```text
output.py
    |
    v
TerraformService.output()
    |
    v
terraform output -json
```

---

# 6. Step 3 — Register the New Tool

File:

```text
app/tools/registry.py
```

Import the new tool:

```python
from app.tools.terraform.output import execute as terraform_output
```

Then add it to the available tools:

```python
def get_available_tools():
    return [
        "terraform_init",
        "terraform_validate",
        "terraform_plan",
        "terraform_explain_plan",
        "terraform_state",
        "terraform_drift",
        "terraform_output",
    ]
```

Then add it to the execution mapping.

For example:

```python
TOOLS = {
    "terraform_init": terraform_init,
    "terraform_validate": terraform_validate,
    "terraform_plan": terraform_plan,
    "terraform_explain_plan": terraform_explain_plan,
    "terraform_state": terraform_state,
    "terraform_drift": terraform_drift,
    "terraform_output": terraform_output,
}
```

If the current `registry.py` uses a slightly different mapping structure, add the new tool to the equivalent execution dictionary/function used by `execute_tool()`.

The key requirement is:

```text
tool name
     |
     v
Python execute function
```

must be registered.

---

# 7. Step 4 — Verify Registry

Run:

```bash
python -c "from app.tools.registry import get_available_tools; print(get_available_tools())"
```

Expected result should contain:

```text
terraform_output
```

For example:

```text
[
    'terraform_init',
    'terraform_validate',
    'terraform_plan',
    'terraform_explain_plan',
    'terraform_state',
    'terraform_drift',
    'terraform_output'
]
```

If the new tool does not appear here, the registry change is incomplete.

---

# 8. Step 5 — Verify the Service Directly

Before testing through the AI agent, test the service.

From the backend project root:

```bash
python -c "from app.services.terraform_service import TerraformService; print(TerraformService.output('/path/to/workspace'))"
```

Inside Docker, the workspace will normally be:

```text
/terraform/workspace
```

Therefore:

```bash
docker exec terraform-agent \
python -c "from app.services.terraform_service import TerraformService; print(TerraformService.output('/terraform/workspace'))"
```

This isolates Terraform execution from the agent.

---

# 9. Step 6 — Verify Tool Execution

Test the registry directly:

```bash
python -c "from app.tools.registry import execute_tool; print(execute_tool('terraform_output', terraform_path='/path/to/workspace'))"
```

Inside Docker:

```bash
docker exec terraform-agent \
python -c "from app.tools.registry import execute_tool; print(execute_tool('terraform_output', terraform_path='/terraform/workspace'))"
```

If this works, the following layers are working:

```text
Service
   |
   v
Tool
   |
   v
Registry
```

---

# 10. Step 7 — Connect the Agent

File:

```text
app/agent/agent.py
```

The agent needs to know when the new tool should be selected.

The exact implementation depends on how the current agent performs intent detection.

Conceptually, add the new capability:

```text
User intent:
"show terraform outputs"
        |
        v
terraform_output
```

Useful phrases could include:

```text
terraform output
show outputs
show terraform outputs
what are the output values
display terraform outputs
```

If the agent uses an explicit tool list, add:

```text
terraform_output
```

If the agent uses an LLM tool definition, expose the new tool there as well.

---

# 11. Important Agent Rule

Do not make the agent execute Terraform directly.

Avoid:

```python
subprocess.run(["terraform", "output"])
```

inside:

```text
agent.py
```

Instead:

```text
agent.py
    |
    v
terraform_output
    |
    v
TerraformService.output()
```

This keeps the architecture maintainable.

---

# 12. Step 8 — API Usually Does NOT Need a New Endpoint

The project uses a generic endpoint:

```text
POST /agent/chat
```

Therefore a new Terraform tool normally does **not** require:

```text
POST /terraform/output
```

The existing flow can remain:

```json
{
    "message": "show terraform outputs"
}
```

The agent decides:

```text
terraform_output
```

and executes it against the selected workspace.

This is one of the main advantages of the agent architecture.

---

# 13. Step 9 — Frontend Usually Does NOT Need Changes

If the frontend already displays generic tool responses, no frontend change is required for a basic new tool.

For example:

```text
User
 |
 | "show terraform outputs"
 v
React
 |
 v
POST /agent/chat
 |
 v
Agent
 |
 v
terraform_output
 |
 v
JSON response
 |
 v
React
```

However, if the new tool produces a special response that needs a custom UI, then add a frontend component.

Example:

```text
src/components/TerraformOutputs.jsx
```

But do this only when the output requires special visualization.

---

# 14. Complete Files That May Need Changes

For a normal new Terraform tool:

```text
REQUIRED
────────────────────────────────────

1. app/services/terraform_service.py
       ↓
   Add Terraform command method

2. app/tools/terraform/<new_tool>.py
       ↓
   Add tool wrapper

3. app/tools/registry.py
       ↓
   Register tool

4. app/agent/agent.py
       ↓
   Make agent capable of selecting the tool
```

Usually unchanged:

```text
app/main.py
frontend
Dockerfile
requirements.txt
```

unless the new tool introduces a new dependency or special UI requirement.

---

# 15. Example: Adding terraform_refresh

Suppose we want:

```text
terraform refresh
```

The implementation would be:

```text
app/
│
├── services/
│   └── terraform_service.py
│
└── tools/
    ├── registry.py
    │
    └── terraform/
        └── refresh.py
```

### Service

```python
@staticmethod
def refresh(terraform_path: str):
    return TerraformService.run_command(
        ["terraform", "refresh"],
        terraform_path
    )
```

### Tool

```python
from app.services.terraform_service import TerraformService


def execute(terraform_path: str):
    return TerraformService.refresh(terraform_path)
```

### Registry

```python
from app.tools.terraform.refresh import execute as terraform_refresh
```

and:

```python
"terraform_refresh": terraform_refresh
```

### Agent

Map:

```text
"refresh terraform"
"terraform refresh"
"refresh state"
```

to:

```text
terraform_refresh
```

---

# 16. Example: Adding a Non-Terraform Tool

The architecture can also support tools outside Terraform.

For example:

```text
docker_ps
```

Recommended structure:

```text
app/
│
├── services/
│   ├── terraform_service.py
│   └── docker_service.py
│
└── tools/
    ├── terraform/
    │   └── ...
    │
    └── docker/
        └── ps.py
```

Flow:

```text
User:
"show running containers"
       |
       v
Agent
       |
       v
docker_ps
       |
       v
DockerService
       |
       v
docker ps
```

This is how the project can gradually become a multi-domain agent.

---

# 17. Recommended Naming Convention

Use clear names.

### Tool names

```text
terraform_init
terraform_validate
terraform_plan
terraform_state
terraform_drift
terraform_output
```

### Files

```text
init.py
validate.py
plan.py
state.py
drift.py
output.py
```

### Service methods

```python
TerraformService.init()
TerraformService.validate()
TerraformService.plan()
TerraformService.state_json()
TerraformService.output()
```

Keep the naming consistent.

---

# 18. Tool Contract

Every tool should have a predictable contract.

Recommended:

```python
def execute(terraform_path: str):
    ...
```

Return:

```json
{
    "status": "success",
    "return_code": 0,
    "data": {}
}
```

For errors:

```json
{
    "status": "error",
    "message": "...",
    "stderr": "..."
}
```

This makes the frontend and agent easier to maintain.

---

# 19. Error Handling

A new tool should handle:

```text
Invalid workspace
Terraform command failure
Terraform not initialized
Invalid JSON
Missing provider
AWS authentication failure
Unexpected exception
```

Example:

```python
if result.returncode != 0:
    return {
        "status": "error",
        "return_code": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr
    }
```

Do not hide Terraform's error information.

The agent/UI needs enough information to explain what went wrong.

---

# 20. Docker Considerations

If the new tool only uses Terraform and Python:

```text
No Dockerfile change normally required.
```

If it requires a new CLI, then the Dockerfile must install it.

Example:

```text
New tool
   |
   v
requires AWS CLI
   |
   v
Dockerfile
   |
   v
install awscli
```

For example:

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip \
        git
```

Do not add unnecessary packages.

---

# 21. Dynamic Workspace Requirement

Every new Terraform tool must use the workspace passed at runtime.

Correct:

```python
def execute(terraform_path: str):
    return TerraformService.output(terraform_path)
```

Correct:

```python
subprocess.run(
    command,
    cwd=terraform_path
)
```

Incorrect:

```python
terraform_path = "/Users/arpitchouksey/Documents/..."
```

The host-specific path belongs outside the application.

The Docker runtime maps:

```text
HOST WORKSPACE
      |
      v
/terraform/workspace
      |
      v
Terraform Agent
```

Therefore every tool should work with:

```text
/terraform/workspace
```

without knowing the original host path.

---

# 22. Testing Checklist

After adding a new tool, test in this order.

### Test 1 — Python imports

```bash
python -c "from app.services.terraform_service import TerraformService; print('Service OK')"
```

### Test 2 — Tool import

```bash
python -c "from app.tools.terraform.output import execute; print('Tool OK')"
```

### Test 3 — Registry

```bash
python -c "from app.tools.registry import get_available_tools; print(get_available_tools())"
```

### Test 4 — Direct execution

```bash
python -c "from app.tools.registry import execute_tool; print(execute_tool('terraform_output', terraform_path='/path/to/workspace'))"
```

### Test 5 — Agent import

```bash
python -c "from app.agent.agent import TerraformAgent; print('Agent OK')"
```

### Test 6 — FastAPI import

```bash
python -c "from app.main import app; print('FastAPI OK')"
```

### Test 7 — API

```bash
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"show terraform outputs"}'
```

---

# 23. Docker Testing

After changing backend code:

```bash
docker stop terraform-agent
docker rm terraform-agent
```

Rebuild:

```bash
docker build -t terraform-agent .
```

Run:

```bash
docker run -d \
  --name terraform-agent \
  -p 8000:8000 \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.aws:/root/.aws:ro \
  -v /YOUR/HOST/TERRAFORM/WORKSPACE:/terraform/workspace \
  terraform-agent
```

Verify:

```bash
docker logs terraform-agent
```

Verify the tool exists:

```bash
docker exec terraform-agent \
python -c "from app.tools.registry import get_available_tools; print(get_available_tools())"
```

---

# 24. Verify Workspace Inside Container

Check:

```bash
docker exec terraform-agent ls -la /terraform/workspace
```

You should see files such as:

```text
main.tf
variables.tf
outputs.tf
```

Then execute the new tool:

```bash
docker exec terraform-agent \
python -c "from app.tools.registry import execute_tool; print(execute_tool('terraform_output', terraform_path='/terraform/workspace'))"
```

---

# 25. Common Mistakes

## Mistake 1 — Forgetting the registry

You create:

```text
output.py
```

but forget:

```text
registry.py
```

Result:

```text
tool not found
```

---

## Mistake 2 — Wrong service method

Tool calls:

```python
TerraformService.output()
```

but the service contains:

```python
TerraformService.outputs()
```

Result:

```text
AttributeError
```

Use the same name everywhere.

---

## Mistake 3 — Hardcoded workspace

Never do:

```python
cwd="/Users/..."
```

Use:

```python
cwd=terraform_path
```

---

## Mistake 4 — Tool bypasses the service

Avoid:

```python
subprocess.run(...)
```

in every tool file.

Prefer:

```text
Tool
 ↓
Service
 ↓
subprocess
```

This prevents duplicated command-execution logic.

---

## Mistake 5 — Rebuilding the frontend unnecessarily

A backend-only tool normally does not require a frontend rebuild.

Only update the frontend if the new response needs custom rendering.

---

# 26. Best Practice for Larger Extensions

When the project grows, organize tools by domain:

```text
app/
│
├── services/
│   ├── terraform_service.py
│   ├── docker_service.py
│   └── kubernetes_service.py
│
└── tools/
    │
    ├── terraform/
    │   ├── init.py
    │   ├── validate.py
    │   ├── plan.py
    │   ├── state.py
    │   ├── drift.py
    │   └── output.py
    │
    ├── docker/
    │   ├── ps.py
    │   ├── images.py
    │   └── logs.py
    │
    └── kubernetes/
        ├── pods.py
        ├── deployments.py
        └── nodes.py
```

Then the architecture becomes:

```text
                 AGENT
                   |
          +--------+--------+
          |        |        |
          v        v        v
      Terraform   Docker   Kubernetes
       Tools      Tools      Tools
          |        |        |
          v        v        v
      Terraform  Docker   kubectl
       Service   Service  Service
```

This is also a strong foundation for the future MCP layer.

---

# 27. Future MCP Design

The existing tools can eventually be exposed through MCP.

Current:

```text
Agent
  |
  v
Tool Registry
  |
  +--> Terraform Tools
  +--> Docker Tools
  +--> Kubernetes Tools
```

Future:

```text
Agent
  |
  v
MCP Client
  |
  v
MCP Server
  |
  +--> terraform_init
  +--> terraform_plan
  +--> terraform_state
  +--> terraform_drift
  +--> terraform_output
  +--> docker_ps
  +--> kubernetes_pods
```

Therefore, adding tools using this structure today makes the project easier to convert to MCP later.

---

# 28. One-Page Developer Checklist

When adding any new tool:

```text
[ ] 1. Define the tool purpose
       |
[ ] 2. Add service method
       |
[ ] 3. Create tool file
       |
[ ] 4. Register tool
       |
[ ] 5. Connect agent intent
       |
[ ] 6. Test service
       |
[ ] 7. Test registry
       |
[ ] 8. Test agent
       |
[ ] 9. Test API
       |
[ ] 10. Test Docker
       |
[ ] 11. Verify dynamic workspace
       |
[ ] 12. Add frontend UI only if required
```

---

# 29. Final Example

Suppose someone says:

> "I want to add a `terraform_output` tool."

The developer should make these changes:

```text
1.
app/services/terraform_service.py
        |
        +-- add output()

2.
app/tools/terraform/output.py
        |
        +-- add execute()

3.
app/tools/registry.py
        |
        +-- import terraform_output
        +-- register terraform_output

4.
app/agent/agent.py
        |
        +-- allow output-related requests
             to select terraform_output

5.
Test:
        |
        +-- service
        +-- tool
        +-- registry
        +-- agent
        +-- API
        +-- Docker

6.
Frontend:
        |
        +-- only modify if special
            output visualization is required
```

The final flow is:

```text
"show terraform outputs"
          |
          v
       React UI
          |
          v
      FastAPI API
          |
          v
     TerraformAgent
          |
          v
   terraform_output
          |
          v
TerraformService.output()
          |
          v
terraform output -json
          |
          v
/terraform/workspace
          |
          v
     Structured JSON
          |
          v
       React UI
```

This is the standard pattern to follow whenever a new tool is added to the project.
