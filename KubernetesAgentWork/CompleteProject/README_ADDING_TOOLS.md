README — How to Add a New Tool

This project is designed so that adding a new Kubernetes tool does not require changing the main FastAPI application or manually registering the tool.

The project uses automatic tool discovery.

1. Overall Tool Flow
                    User Request
                         │
                         ▼
                  FastAPI /agent/chat
                         │
                         ▼
                    run_agent()
                         │
                         ▼
                    Ollama / LLM
                         │
              Selects tool + arguments
                         │
                         ▼
                 Tool Registry
                         │
                         ▼
              Execute Python Tool
                         │
                         ▼
             Kubernetes / kubectl
                         │
                         ▼
                  Tool Result
                         │
                         ▼
                  FastAPI Response

The important part is:

New Python Tool
      ↓
app/tools/
      ↓
tool_loader.py automatically discovers it
      ↓
Ollama receives its description
      ↓
LLM can select it
      ↓
agent.py executes it
2. Where Do I Add a New Tool?

All tools belong under:

app/
└── tools/

The existing project organizes tools by Kubernetes resource:

app/tools/
│
├── pods/
│   ├── get_pods.py
│   ├── get_all_pods.py
│   ├── describe_pod.py
│   ├── get_pod_logs.py
│   ├── create_pod.py
│   └── delete_pod.py
│
├── deployments/
│   ├── get_deployments.py
│   ├── create_deployment.py
│   ├── scale_deployment.py
│   └── delete_deployment.py
│
├── namespace/
│   ├── create_namespace.py
│   ├── list_namespaces.py
│   └── delete_namespace.py
│
├── cluster/
├── services/
├── troubleshooting/
└── ...

So if you want to add a new Pod-related operation:

app/tools/pods/

If you want a new Deployment operation:

app/tools/deployments/
3. Create the Python Tool

For example, suppose we want to add:

Get the number of replicas for a deployment.

Create:

app/tools/deployments/get_replicas.py

Example:

from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def get_replicas(
    name: str,
    namespace: str = "default"
):
    """
    Get the replica count of a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "get",
            "deployment",
            name,
            "-n",
            namespace,
            "-o",
            "jsonpath={.spec.replicas}"
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "deployment",
        "name": name,
        "namespace": namespace,
        "replicas": result["stdout"]
    }
4. Why @kubernetes_tool Is Important

This line:

@kubernetes_tool

marks the function as an agent tool.

The decorator in:

app/agent/tool.py

automatically adds:

is_agent_tool = True

and:

tool_name = func.__name__

and:

tool_description = inspect.getdoc(func)

Therefore:

@kubernetes_tool
def get_replicas(...):

automatically becomes:

Tool name:
get_replicas

Description:
Get the replica count of a Kubernetes deployment.
5. Do I Need to Change main.py?
No.

This is one of the important design decisions in this project.

main.py only handles the API:

@app.post("/agent/chat")
def chat(request: dict):

    message = request.get("message", "")

    return run_agent(message)

You do not add your new tool here.

6. Do I Need to Change agent.py?
No.

agent.py gets the tools automatically:

self.tools = get_tools()

Then, when Ollama returns:

{
  "type": "tool_call",
  "tool": "get_replicas",
  "arguments": {
    "name": "nginx",
    "namespace": "default"
  }
}

the agent does:

tool = self.tools.get(tool_name)

and executes:

result = tool["function"](**arguments)

So the agent does not need a hardcoded:

if tool == "get_replicas":

This is what makes the architecture extensible.

7. How Does the New Tool Get Discovered?

This happens in:

app/agent/tool_loader.py

The loader walks through:

app.tools

using:

pkgutil.walk_packages(...)

It imports the discovered modules.

Then it checks every function for:

is_agent_tool

Specifically:

if getattr(
    attribute,
    "is_agent_tool",
    False
):

Therefore:

app/tools/deployments/get_replicas.py
                     │
                     ▼
              tool_loader.py
                     │
                     ▼
              @kubernetes_tool
                     │
                     ▼
              is_agent_tool=True
                     │
                     ▼
              Registered automatically
8. How Does Ollama Know About the Tool?

This is handled in:

app/agent/llm.py

The agent passes all discovered tools to:

call_llm(
    message=message,
    tools=self.tools
)

Then the tool descriptions are created:

for name, tool in tools.items():

    tool_descriptions.append({
        "name": name,
        "description": tool.get(
            "description",
            ""
        )
    })

So Ollama receives something conceptually like:

Available Kubernetes tools:

get_pods
Get pods in a Kubernetes namespace.

get_pod_logs
Get logs from a Kubernetes Pod.

describe_pod
Show detailed information and events for a pod.

get_replicas
Get the replica count of a Kubernetes deployment.

The LLM can then decide:

User:
"How many replicas does nginx have?"

        ↓

Ollama

        ↓

get_replicas

        ↓

{
  "name": "nginx",
  "namespace": "default"
}
9. Do I Need to Change the Ollama Prompt?
Usually, no.

The tool description is automatically supplied to Ollama.

However, for important or ambiguous tools, it is useful to add an example to the SYSTEM_PROMPT in:

app/agent/llm.py

For example:

"how many replicas does nginx have"

=> get_replicas

This is optional but can improve tool selection.

10. Complete New Tool Flow

After creating:

app/tools/deployments/get_replicas.py

the complete flow becomes:

                  curl
                   │
                   ▼
          POST /agent/chat
                   │
                   ▼
             main.py
                   │
                   ▼
             run_agent()
                   │
                   ▼
              agent.py
                   │
                   ▼
              call_llm()
                   │
                   ▼
              Ollama
                   │
                   ▼
             get_replicas
                   │
                   ▼
          tool_loader registry
                   │
                   ▼
         get_replicas function
                   │
                   ▼
            run_kubectl()
                   │
                   ▼
             Kubernetes
                   │
                   ▼
               Result
                   │
                   ▼
                curl
11. Files You Normally Change

When adding a simple tool, you normally only need:

CREATE:

app/tools/<category>/<new_tool>.py

That's it.

Optional

If Ollama needs stronger routing guidance:

MODIFY:

app/agent/llm.py
Usually DON'T modify:
app/main.py
app/agent/agent.py
app/agent/tool_loader.py
app/agent/tool.py

because these are already designed to support dynamic tools.

12. Example: Adding get_services

Suppose a developer wants:

"Show me Kubernetes services."

Create:

app/tools/services/get_services.py

Then:

@kubernetes_tool
def get_services(...):
    ...

The loader automatically finds it:

get_services.py
       ↓
tool_loader.py
       ↓
get_services registered
       ↓
Ollama receives description
       ↓
User asks "show services"
       ↓
Ollama selects get_services
       ↓
agent.py executes it

No manual registration is required.

13. Testing the New Tool

Start the application:

python -m uvicorn app.main:app --reload --port 8000

Then test:

curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"show me Kubernetes services"}'

The expected conceptual flow is:

HTTP Request
     ↓
FastAPI
     ↓
Ollama
     ↓
get_services
     ↓
kubectl get services
     ↓
Kubernetes
     ↓
JSON Response
14. Developer Checklist

When adding a new tool:

[ ] 1. Decide the Kubernetes operation

[ ] 2. Create a .py file under app/tools/

[ ] 3. Create a Python function

[ ] 4. Add @kubernetes_tool

[ ] 5. Add a clear docstring

[ ] 6. Define the required arguments

[ ] 7. Call Kubernetes API / kubectl

[ ] 8. Return a dictionary result

[ ] 9. Restart FastAPI if required

[ ] 10. Test using curl
The key interview point

You can explain the extensibility like this:

"The application uses dynamic tool discovery. I don't hardcode every tool inside the FastAPI endpoint or agent. A developer only creates a Python function under app/tools and marks it with the @kubernetes_tool decorator. The tool loader automatically discovers it, extracts its name and description, and passes it to Ollama. Ollama selects the appropriate tool based on the user's request, and the agent executes the function dynamically."

The most important architecture principle is:

              NEW TOOL
                 │
                 ▼
        app/tools/<tool>.py
                 │
                 ▼
          @kubernetes_tool
                 │
                 ▼
        Automatic Discovery
                 │
                 ▼
              Ollama
                 │
                 ▼
          Dynamic Execution

So the project is intentionally built as a plug-in style tool architecture: adding capabilities primarily means adding a new tool file, rather than modifying the core agent.
