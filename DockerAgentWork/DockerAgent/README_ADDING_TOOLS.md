# Adding a New Tool to Docker Agent

This document explains how to add a new tool to the Docker Agent project.

The project is designed so that a developer can add a new Docker/Linux operation without changing the complete agent architecture.

---

# 1. Current Architecture

The basic flow is:

User
 |
 | Natural Language Request
 v
FastAPI
 |
 v
DockerLLMAgent
 |
 | Select Tool
 v
Tool Registry
 |
 v
Python Tool
 |
 v
Docker / Linux
 |
 v
Tool Result
 |
 v
LLM / Agent Response
 |
 v
User


Example:

User:
"Show all Docker images"

        |
        v

LLM

        |
        v

docker_images()

        |
        v

Docker CLI

        |
        v

Result

        |
        v

User

2. Important Files

The main files involved in adding a tool are:

docker-agent/
│
├── app/
│   ├── docker_tools.py
│   ├── linux_tools.py
│   ├── tool_registry.py
│   └── llm_agent.py
│
└── api/
    └── server.py
Responsibilities
File	Responsibility
app/docker_tools.py	Docker-related tools
app/linux_tools.py	Linux/system tools
app/tool_registry.py	Registers/exposes tools to the application
app/llm_agent.py	Sends request to LLM and selects tool
api/server.py	FastAPI API layer
3. Where Should I Add My New Tool?

First decide what type of tool you are creating.

Docker Tool

Add it to:

app/docker_tools.py

Examples:

docker_ps
docker_images
docker_container_inspect
docker_container_logs
Linux/System Tool

Add it to:

app/linux_tools.py

Examples:

process_list
disk_usage
memory_usage
New Category of Tool

Create a new file.

For example:

app/kubernetes_tools.py

or:

app/terraform_tools.py

Then register the new tools in:

app/tool_registry.py
4. Simplest Example

Suppose we want to add a new Docker tool:

docker_restart

The purpose is to restart a Docker container.

5. Step 1 — Create the Function

Open:

app/docker_tools.py

Add:

def docker_restart(name: str):
    command = [
        "docker",
        "restart",
        name,
    ]

    return _run_docker_command(command)

That's the actual Python implementation of the tool.

6. Step 2 — Register the Tool

At the bottom of:

app/docker_tools.py

there is:

def get_docker_tools():

    return {
        "docker_ps": docker_ps,
        "docker_images": docker_images,
        "docker_container_inspect": docker_container_inspect,
        "docker_container_logs": docker_container_logs,
    }

Add the new tool:

def get_docker_tools():

    return {
        "docker_ps": docker_ps,
        "docker_images": docker_images,
        "docker_container_inspect": docker_container_inspect,
        "docker_container_logs": docker_container_logs,
        "docker_restart": docker_restart,
    }

This is very important.

Simply creating the Python function is not enough.

The tool must be exposed through the tool registry.

7. Step 3 — Tool Registry

Open:

app/tool_registry.py

The current project combines Docker and Linux tools:

from app.docker_tools import get_docker_tools
from app.linux_tools import get_linux_tools


def get_all_tools():

    tools = {}

    tools.update(get_docker_tools())
    tools.update(get_linux_tools())

    return tools

Because we already added docker_restart() to:

get_docker_tools()

we do NOT need to modify tool_registry.py.

The flow automatically becomes:

docker_restart()
       |
       v
get_docker_tools()
       |
       v
get_all_tools()
       |
       v
DockerLLMAgent
8. Step 4 — FastAPI

Normally, you do NOT need to change:

api/server.py

The server already loads all registered tools:

tools = get_all_tools()

agent = DockerLLMAgent(
    tools=tools
)

Therefore, when a new tool is registered, it automatically becomes available to the agent.

9. Step 5 — LLM Tool Selection

The important part of the project is:

app/llm_agent.py

The agent receives the registered tools:

class DockerLLMAgent:

    def __init__(self, tools):

        self.tools = tools

The available tool names are obtained dynamically:

tool_names = list(self.tools.keys())

Therefore, after adding:

docker_restart

the LLM can see it as an available tool.

10. Tool Selection Flow

Suppose the user says:

Restart my nginx container

The flow becomes:

User
 |
 | "Restart my nginx container"
 v
FastAPI
 |
 v
DockerLLMAgent
 |
 v
LLM
 |
 | Understand intent
 v
docker_restart
 |
 | name = nginx
 v
docker_restart("nginx")
 |
 v
docker restart nginx
 |
 v
Docker
 |
 v
Result

The important point is:

The user does not need to know the Python function name.

The LLM maps the natural-language request to the available tool.

11. Important: Tool Parameters

If your tool requires parameters, define them clearly.

Example:

def docker_restart(name: str):

    command = [
        "docker",
        "restart",
        name,
    ]

    return _run_docker_command(command)

The parameter is:

name

The LLM can then determine that:

"Restart nginx"

means:

{
    "name": "nginx"
}

and execute:

docker_restart(
    name="nginx"
)
12. Read-Only Tool Example

Suppose you want to add:

docker_version

Add to:

app/docker_tools.py
def docker_version():

    command = [
        "docker",
        "--version",
    ]

    return _run_docker_command(command)

Then register it:

def get_docker_tools():

    return {
        "docker_ps": docker_ps,
        "docker_images": docker_images,
        "docker_container_inspect": docker_container_inspect,
        "docker_container_logs": docker_container_logs,
        "docker_version": docker_version,
    }

No change is required in:

api/server.py

because the server loads the complete tool registry.

13. Creating a New Tool Category

Suppose another developer wants to add Kubernetes tools.

Create:

app/kubernetes_tools.py

Example:

import subprocess


def kubectl(command):

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
    )

    return {
        "status": (
            "SUCCESS"
            if result.returncode == 0
            else "ERROR"
        ),
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
    }


def kubectl_get_pods():

    return kubectl([
        "kubectl",
        "get",
        "pods",
    ])


def get_kubernetes_tools():

    return {
        "kubectl_get_pods": kubectl_get_pods,
    }

Then modify:

app/tool_registry.py

Add:

from app.kubernetes_tools import get_kubernetes_tools

Then:

def get_all_tools():

    tools = {}

    tools.update(get_docker_tools())
    tools.update(get_linux_tools())
    tools.update(get_kubernetes_tools())

    return tools

Now the architecture becomes:

Tool Registry
     |
     ├── Docker Tools
     |
     ├── Linux Tools
     |
     └── Kubernetes Tools
14. Adding a Tool — Complete Checklist

Whenever you create a new tool, follow these steps.

1. Decide the tool category
        |
        v
2. Add Python function
        |
        v
3. Add function to get_<category>_tools()
        |
        v
4. Confirm tool_registry.py exposes the category
        |
        v
5. Confirm LLM can see the tool
        |
        v
6. Start FastAPI
        |
        v
7. Check /tools
        |
        v
8. Test using natural language
15. Check Registered Tools

After adding a tool, start the backend:

python -m uvicorn api.server:app --reload --port 8000

Then:

curl http://127.0.0.1:8000/tools

You should see your new tool.

For example:

{
    "status": "SUCCESS",
    "tools": [
        "docker_ps",
        "docker_images",
        "docker_container_inspect",
        "docker_container_logs",
        "docker_restart",
        "process_list",
        "disk_usage",
        "memory_usage"
    ]
}

If docker_restart appears here, the tool is successfully registered.

16. Test the New Tool

Send a natural-language request:

curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Restart the nginx container"}'

The expected flow is:

"Restart the nginx container"
              |
              v
             LLM
              |
              v
       docker_restart
              |
              v
      docker restart nginx
17. Testing the Tool Directly

Before testing through the LLM, it is a good practice to test the Python function itself.

For example:

python -c "from app.docker_tools import docker_restart; print(docker_restart('nginx'))"

This separates two possible problems:

Tool Problem
     OR
LLM/Agent Problem

If direct execution works but the LLM does not select the tool, the problem is most likely in the agent/tool-selection layer.

18. Tool Development Best Practice

Keep the tool itself simple.

A good tool should generally:

Receive parameters
       |
       v
Validate parameters
       |
       v
Execute one operation
       |
       v
Return structured result

Example:

def docker_version():

    command = [
        "docker",
        "--version",
    ]

    return _run_docker_command(command)

Avoid putting LLM logic inside the Docker tool.

The responsibilities should remain separate:

LLM
 |
 | Decides WHAT to do
 v
Tool
 |
 | Performs HOW to do it
 v
Docker / Linux
19. Do Not Put LLM Logic Inside Tools

Avoid:

def docker_restart():

    # Call LLM
    # Ask LLM what to do
    # Execute Docker

Instead:

LLM
 |
 | Select docker_restart
 v
docker_restart()
 |
 v
Docker

This keeps the architecture clean.

20. Read vs Write Operations

Tools should also be classified conceptually as:

Read

Examples:

docker_ps
docker_images
docker_container_inspect
docker_container_logs
memory_usage
disk_usage

These only retrieve information.

Write

Examples:

docker_restart
docker_stop
docker_remove
docker_run

These modify the environment.

Write operations should have an approval/safety mechanism before being used in a production environment.

21. Example: Adding docker_stop
Step 1

Open:

app/docker_tools.py

Add:

def docker_stop(name: str):

    command = [
        "docker",
        "stop",
        name,
    ]

    return _run_docker_command(command)
Step 2

Register it:

def get_docker_tools():

    return {
        "docker_ps": docker_ps,
        "docker_images": docker_images,
        "docker_container_inspect": docker_container_inspect,
        "docker_container_logs": docker_container_logs,
        "docker_stop": docker_stop,
    }
Step 3

Restart FastAPI.

Step 4

Verify:

curl http://127.0.0.1:8000/tools
Step 5

Test:

curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Stop the nginx container"}'
22. What Files Usually Need Modification?

For a normal Docker tool:

app/docker_tools.py
        |
        | Add function
        |
        | Register function
        v
get_docker_tools()

Usually no changes are required in:

api/server.py
app/llm_agent.py

because the current architecture dynamically passes registered tools to the agent.

For a completely new category:

Create:
app/<new_category>_tools.py

Then modify:
app/tool_registry.py
23. Quick Reference
Add Docker Tool
app/docker_tools.py

Add:

def my_tool(...):
    ...

Register:

def get_docker_tools():

    return {
        ...
        "my_tool": my_tool,
    }

Done.

Add Linux Tool
app/linux_tools.py

Add:

def my_linux_tool(...):
    ...

Register:

def get_linux_tools():

    return {
        ...
        "my_linux_tool": my_linux_tool,
    }

Done.

Add Completely New Tool Category

Create:

app/new_tools.py

Add:

def new_tool(...):
    ...


def get_new_tools():

    return {
        "new_tool": new_tool,
    }

Then update:

app/tool_registry.py

with:

from app.new_tools import get_new_tools

and:

tools.update(get_new_tools())
24. Final Flow for Adding Any Tool
                 Developer
                     |
                     v
          Create Python Function
                     |
                     v
             Register Function
                     |
                     v
              Tool Registry
                     |
                     v
                FastAPI
                     |
                     v
                  LLM
                     |
             Understand Intent
                     |
                     v
              Select Tool
                     |
                     v
              Execute Tool
                     |
                     v
             Docker / Linux
                     |
                     v
                  Result
                     |
                     v
                   User
25. One-Minute Interview Explanation

If an interviewer asks:

"How would you add a new tool to your Agent?"

You can answer:

"I would first create the Python function in the appropriate tool module, such as docker_tools.py. Then I would register that function inside get_docker_tools(). The central tool_registry.py combines the available tools, and api/server.py passes them to the LLM agent. Because the agent receives the registered tool names dynamically, I normally don't need to modify the FastAPI or LLM code for every new tool. Finally, I verify the tool through /tools and test it using a natural-language request."

The complete development pattern is:

Create Tool
    ↓
Register Tool
    ↓
Tool Registry
    ↓
LLM Sees Tool
    ↓
User Request
    ↓
LLM Selects Tool
    ↓
Tool Executes
    ↓
Result
Important Note

The repository contains both app/agent.py and app/llm_agent.py.

The current FastAPI server in:

api/server.py

uses:

from app.llm_agent import DockerLLMAgent

and:

tools = get_all_tools()

agent = DockerLLMAgent(
    tools=tools
)

Therefore, when extending the current FastAPI agent flow, the primary path to follow is:

api/server.py
        ↓
app/llm_agent.py
        ↓
app/tool_registry.py
        ↓
app/docker_tools.py
app/linux_tools.py

app/agent.py represents a separate/older agent implementation in the repository and should not be modified just to add a normal tool to the current /agent/chat API flow.


### The key thing for another developer

They only need to remember this:

```text
For Docker:
app/docker_tools.py
        ↓
get_docker_tools()

For Linux:
app/linux_tools.py
        ↓
get_linux_tools()

For a new category:
create app/<category>_tools.py
        ↓
modify app/tool_registry.py

Then the existing LLM → tool selection → execution flow picks up the newly registered tool.
