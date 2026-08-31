# Kubernetes AI Agent --- Bedrock + MCP + Kubernetes

A Kubernetes AI Agent that uses **Amazon Bedrock** for reasoning and
**Model Context Protocol (MCP)** servers for Kubernetes operations.

## Features

-   Standard Kubernetes MCP tools for read-only cluster information.
-   Custom Kubernetes MCP server for project-specific operations.
-   `restart_pod` custom tool.
-   FastAPI backend.
-   React/Vite frontend.
-   Amazon Bedrock / Nova Lite for reasoning and tool selection.

## Architecture

``` text
React UI
   |
   | POST /api/chat
   v
FastAPI Backend :8000
   |
   v
Kubernetes Agent
   |
   +------------------------------+
   |                              |
   v                              v
Standard Kubernetes MCP       Custom Kubernetes MCP
127.0.0.1:8080                127.0.0.1:8081
   |                              |
   | read-only tools               | custom tools
   |                              |
   +--------------+---------------+
                  |
                  v
             Kubernetes
             docker-desktop
```

Bedrock decides which discovered MCP tool is appropriate for the user's
natural-language request.

## Components

  Component                 Purpose                             Port
  ------------------------- --------------------------- ------------
  React/Vite                User interface                    `5174`
  FastAPI                   Backend API                       `8000`
  Standard Kubernetes MCP   Existing Kubernetes tools         `8080`
  Custom Kubernetes MCP     Custom tools                      `8081`
  Kubernetes                Target cluster                kubeconfig
  Amazon Bedrock            LLM/tool selection                   AWS

------------------------------------------------------------------------

# 1. Project Structure

``` text
kubernetes-mcp-bedrock/
│
├── app/
│   ├── agent.py
│   └── api.py
│
├── custom_mcp/
│   └── server.py
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── vite.config.js
│
├── .venv/
├── requirements.txt
└── README.md
```

Your exact frontend directory may differ.

------------------------------------------------------------------------

# 2. Prerequisites

Install/configure:

-   Python
-   Node.js and npm
-   Docker Desktop with Kubernetes enabled, or another Kubernetes
    cluster
-   `kubectl`
-   AWS credentials
-   Amazon Bedrock model access

Check Kubernetes:

``` bash
kubectl config current-context
kubectl get nodes
```

For the local setup, the expected context is:

``` text
docker-desktop
```

------------------------------------------------------------------------

# 3. Create Python Environment

From the project root:

``` bash
python3 -m venv .venv
source .venv/bin/activate
```

Verify:

``` bash
python -c "import sys; print(sys.executable)"
```

It should point to the project's `.venv/bin/python`.

------------------------------------------------------------------------

# 4. Install Python Dependencies

``` bash
python -m pip install --upgrade pip
python -m pip install fastapi uvicorn boto3 kubernetes mcp
```

Check MCP:

``` bash
python -m pip show mcp
```

The working environment used for this project has:

``` text
mcp 1.29.1
```

For this version, FastMCP is imported as:

``` python
from mcp.server.fastmcp import FastMCP
```

Do not use the old/incompatible:

``` python
from mcp.server.mcpserver import MCPServer
```

------------------------------------------------------------------------

# 5. AWS / Bedrock

Configure AWS credentials using your normal AWS CLI/profile/environment
configuration.

Verify:

``` bash
aws sts get-caller-identity
```

Make sure your configured AWS region has access to the Bedrock model
used by the application.

Bedrock is responsible for reasoning and selecting the appropriate MCP
tool.

------------------------------------------------------------------------

# 6. Start Standard Kubernetes MCP

Start the existing Kubernetes MCP server used by the project.

The agent expects:

``` text
http://127.0.0.1:8080/mcp
```

The standard server exposes tools such as:

``` text
configuration_contexts_list
configuration_view
events_list
namespaces_list
nodes_log
nodes_stats_summary
nodes_top
pods_get
pods_list
pods_list_in_namespace
pods_log
pods_top
projects_list
resources_get
resources_list
```

The agent discovers these tools dynamically.

------------------------------------------------------------------------

# 7. Start Custom Kubernetes MCP

Custom code is located at:

``` text
custom_mcp/server.py
```

Start it:

``` bash
source .venv/bin/activate
python custom_mcp/server.py
```

Expected MCP endpoint:

``` text
http://127.0.0.1:8081/mcp
```

The current custom server exposes:

``` text
restart_pod
```

## Important MCP 1.29.1 detail

With MCP 1.29.1, configure the HTTP host and port when creating
`FastMCP`.

Example:

``` python
mcp = FastMCP(
    "Custom Kubernetes MCP",
    host="127.0.0.1",
    port=8081,
    streamable_http_path="/mcp",
)
```

Then:

``` python
mcp.run(transport="streamable-http")
```

Do not do:

``` python
mcp.run(
    transport="streamable-http",
    host="127.0.0.1",
    port=8081,
)
```

because `FastMCP.run()` does not accept `host` and `port` arguments in
this SDK version.

------------------------------------------------------------------------

# 8. Start FastAPI Backend

Open another terminal:

``` bash
cd kubernetes-mcp-bedrock
source .venv/bin/activate
```

Run:

``` bash
uvicorn app.api:app --host 127.0.0.1 --port 8000 --reload
```

Expected:

``` text
Uvicorn running on http://127.0.0.1:8000
```

## Health check

``` bash
curl http://127.0.0.1:8000/health
```

Expected:

``` json
{
  "status": "ok",
  "service": "kubernetes-ai-agent"
}
```

------------------------------------------------------------------------

# 9. Test Backend Without UI

Always test FastAPI with curl before testing React.

## List namespaces

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all namespaces"}'
```

The response should contain only the namespace result.

## List all pods

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all pods"}'
```

Example result:

``` text
default | agent-nginx | 1/1 | Running
default | nginx-xxxx | 1/1 | Running
kube-system | coredns-xxxx | 1/1 | Running
...
```

The agent should return the requested Kubernetes information rather than
dumping the complete MCP tool list.

------------------------------------------------------------------------

# 10. Test Custom `restart_pod`

First check the pod:

``` bash
kubectl get pods -A
```

Then ask the agent:

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Restart pod <pod-name> in namespace <namespace>"}'
```

Example:

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Restart pod nginx-66686b6766-qsdng in namespace default"}'
```

The expected flow is:

``` text
User request
      |
      v
FastAPI
      |
      v
Agent
      |
      v
Amazon Bedrock
      |
      v
restart_pod
      |
      v
Custom Kubernetes MCP :8081
      |
      v
Kubernetes API
      |
      v
Pod deleted
      |
      v
Deployment/ReplicaSet creates replacement
```

Verify:

``` bash
kubectl get pods -n default
```

------------------------------------------------------------------------

# 11. Start React UI

Open another terminal:

``` bash
cd frontend
npm install
```

Run Vite:

``` bash
npm run dev -- --port 5174
```

Open:

``` text
http://localhost:5174
```

The React application calls:

``` text
http://127.0.0.1:8000/api/chat
```

React should communicate with FastAPI, not directly with Kubernetes.

------------------------------------------------------------------------

# 12. Run All Components

Use four terminals.

## Terminal 1 --- Standard Kubernetes MCP

Start the existing Kubernetes MCP server.

Expected:

``` text
http://127.0.0.1:8080/mcp
```

## Terminal 2 --- Custom MCP

``` bash
source .venv/bin/activate
python custom_mcp/server.py
```

Expected:

``` text
http://127.0.0.1:8081/mcp
```

## Terminal 3 --- FastAPI

``` bash
source .venv/bin/activate
uvicorn app.api:app --host 127.0.0.1 --port 8000 --reload
```

Expected:

``` text
http://127.0.0.1:8000
```

## Terminal 4 --- React

``` bash
cd frontend
npm run dev -- --port 5174
```

Expected:

``` text
http://localhost:5174
```

------------------------------------------------------------------------

# 13. Complete Test Sequence

### Kubernetes

``` bash
kubectl get nodes
```

### FastAPI health

``` bash
curl http://127.0.0.1:8000/health
```

### Namespaces

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all namespaces"}'
```

### Pods

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all pods"}'
```

### Restart pod

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Restart pod <pod-name> in namespace <namespace>"}'
```

### UI

Open:

``` text
http://localhost:5174
```

------------------------------------------------------------------------

# 14. How Multiple MCP Servers Work

The agent connects to both MCP servers.

``` text
                    Agent
                      |
             Amazon Bedrock
                      |
          Tool selection / reasoning
                      |
          +-----------+-----------+
          |                       |
          v                       v
 Standard MCP                Custom MCP
    :8080                       :8081
          |                       |
          v                       v
 read-only tools             custom tools
          |                       |
          +-----------+-----------+
                      |
                      v
                 Kubernetes
```

Examples:

### User

``` text
List all namespaces
```

Bedrock selects:

``` text
namespaces_list
```

### User

``` text
List all pods
```

Bedrock selects:

``` text
pods_list
```

### User

``` text
Restart pod nginx-123 in namespace default
```

Bedrock selects:

``` text
restart_pod
```

This means the UI does not need a separate hard-coded implementation for
each Kubernetes operation.

------------------------------------------------------------------------

# 15. How to Add Custom Tools

Custom project-specific tools should be added to:

``` text
custom_mcp/server.py
```

Do not modify the standard Kubernetes MCP server just to add
project-specific operations.

The basic pattern is:

``` python
@mcp.tool()
def my_custom_tool(parameter: str) -> str:
    """
    Clear description of what the tool does.
    """
    # Kubernetes API operation
    return "Result"
```

The important decorator is:

``` python
@mcp.tool()
```

This exposes the Python function as an MCP tool.

------------------------------------------------------------------------

# 16. Example: Add Another Tool

Suppose you want to add a deployment status tool.

In:

``` text
custom_mcp/server.py
```

add:

``` python
@mcp.tool()
def get_deployment_status(
    deployment_name: str,
    namespace: str = "default",
) -> str:
    """
    Get the status of a Kubernetes Deployment.
    """

    try:
        deployment = apps_v1.read_namespaced_deployment(
            name=deployment_name,
            namespace=namespace,
        )

        desired = deployment.spec.replicas or 0
        available = deployment.status.available_replicas or 0

        return (
            f"Deployment '{deployment_name}' in namespace "
            f"'{namespace}': {available}/{desired} replicas available."
        )

    except Exception as exc:
        return (
            f"Failed to get deployment "
            f"'{deployment_name}' in namespace '{namespace}': {exc}"
        )
```

After restarting the custom MCP server, the new tool can be discovered
by the agent.

------------------------------------------------------------------------

# 17. Custom Tool Development Flow

Whenever adding a new tool:

``` text
1. Decide the Kubernetes operation
             |
             v
2. Edit custom_mcp/server.py
             |
             v
3. Add @mcp.tool()
             |
             v
4. Define clear parameters
             |
             v
5. Implement Kubernetes API call
             |
             v
6. Return a clean result
             |
             v
7. Restart custom MCP
             |
             v
8. Test with curl
             |
             v
9. Test from React UI
```

------------------------------------------------------------------------

# 18. Do I Need to Change the Frontend?

For a normal agent-driven MCP tool: **No.**

For example, adding:

``` text
get_deployment_status
```

does not require a new React button.

The user can simply type:

``` text
Show deployment status for nginx in namespace default
```

The flow is:

``` text
React
  |
  v
POST /api/chat
  |
  v
Agent
  |
  v
Bedrock
  |
  v
get_deployment_status
  |
  v
Custom MCP
  |
  v
Kubernetes
```

The agent discovers the new MCP tool automatically.

Only add frontend code if you specifically want a dedicated UI control,
form, table, confirmation dialog, etc.

------------------------------------------------------------------------

# 19. Important Custom Tool Guidelines

## Clear names

Good:

``` text
restart_pod
get_pod_events
get_deployment_status
scale_deployment
```

Avoid:

``` text
do_it
operation
execute
```

## Clear descriptions

The tool description should explain exactly when the tool should be
used.

## Explicit parameters

Good:

``` python
def restart_pod(
    pod_name: str,
    namespace: str = "default",
)
```

## Clean return values

Prefer:

``` text
Pod nginx-123 restarted successfully.
```

instead of returning a huge raw Kubernetes Python object.

## Destructive operations

Operations such as:

``` text
restart_pod
delete_pod
scale_deployment
delete_deployment
```

should have very clear descriptions and should be handled carefully.

------------------------------------------------------------------------

# 20. Port Reference

``` text
React UI                  5174
FastAPI                   8000
Standard Kubernetes MCP  8080
Custom Kubernetes MCP    8081
```

If Vite's default port `5173` is already occupied, use:

``` bash
npm run dev -- --port 5174
```

This is a runtime override and does not require permanently changing
`vite.config.js`.

------------------------------------------------------------------------

# 21. Common Troubleshooting

## UI says `Failed to fetch`

Check:

``` bash
curl http://127.0.0.1:8000/health
```

If this fails, FastAPI is not running.

## `/api/chat` returns `404`

Start the correct FastAPI application:

``` bash
uvicorn app.api:app --host 127.0.0.1 --port 8000 --reload
```

## Port 8000 already in use

``` bash
lsof -i :8000
```

Stop the old process if appropriate:

``` bash
kill <PID>
```

## Port 8081 already in use

``` bash
lsof -i :8081
```

Stop the old custom MCP process if appropriate.

## Kubernetes Python package missing

``` bash
python -m pip install kubernetes
```

Verify:

``` bash
python -c "from kubernetes import client, config; print('Kubernetes client OK')"
```

## FastMCP import error

Check:

``` bash
python -m pip show mcp
```

For MCP 1.29.1:

``` bash
python -c "from mcp.server.fastmcp import FastMCP; print('FastMCP OK')"
```

------------------------------------------------------------------------

# 22. Useful Kubernetes Commands

Current context:

``` bash
kubectl config current-context
```

Nodes:

``` bash
kubectl get nodes
```

Namespaces:

``` bash
kubectl get namespaces
```

All pods:

``` bash
kubectl get pods -A
```

Pods in a namespace:

``` bash
kubectl get pods -n <namespace>
```

Pod details:

``` bash
kubectl describe pod <pod-name> -n <namespace>
```

Pod logs:

``` bash
kubectl logs <pod-name> -n <namespace>
```

------------------------------------------------------------------------

# 23. Final Working Architecture

``` text
                         React UI
                       localhost:5174
                            |
                            v
                       FastAPI :8000
                            |
                            v
                    Kubernetes Agent
                            |
                            v
                     Amazon Bedrock
                            |
                 +----------+----------+
                 |                     |
                 v                     v
        Standard Kubernetes MCP    Custom MCP
              :8080                  :8081
                 |                     |
                 |                     |
                 +----------+----------+
                            |
                            v
                       Kubernetes
```

The standard MCP provides existing Kubernetes tools.

The custom MCP provides project-specific tools such as:

``` text
restart_pod
```

Additional tools can be added to:

``` text
custom_mcp/server.py
```

without changing the standard Kubernetes MCP implementation.

------------------------------------------------------------------------

# 24. Quick Start

``` bash
# Terminal 1
# Start standard Kubernetes MCP on 8080
```

``` bash
# Terminal 2
source .venv/bin/activate
python custom_mcp/server.py
```

``` bash
# Terminal 3
source .venv/bin/activate
uvicorn app.api:app --host 127.0.0.1 --port 8000 --reload
```

``` bash
# Terminal 4
cd frontend
npm run dev -- --port 5174
```

Open:

``` text
http://localhost:5174
```

Health:

``` bash
curl http://127.0.0.1:8000/health
```

Namespaces:

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all namespaces"}'
```

Pods:

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"List all pods"}'
```

Restart:

``` bash
curl -X POST http://127.0.0.1:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Restart pod <pod-name> in namespace <namespace>"}'
```

------------------------------------------------------------------------

# Project Status

The completed project supports:

-   Kubernetes `docker-desktop`
-   Standard Kubernetes MCP
-   Custom Kubernetes MCP
-   `restart_pod`
-   FastAPI backend
-   React/Vite UI
-   Amazon Bedrock / Nova Lite
-   Natural-language Kubernetes queries
-   Multiple MCP servers
-   Extensible custom MCP tools
