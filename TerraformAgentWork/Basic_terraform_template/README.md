Terraform Agent — Basic FastAPI + Ollama
1. Project Overview

This project is a basic Terraform Agent built with:

FastAPI — provides the REST API/chat endpoint.
Terraform CLI — executes Terraform operations.
Ollama — provides natural-language responses for prompts that are not mapped to Terraform tools.
Python subprocess — executes Terraform commands from Python.
Python requests — communicates with Ollama.

The agent currently supports two Terraform tools:

terraform init
terraform plan

Users interact with the application through a single /chat API endpoint using natural language.

2. Architecture
                    User
                     |
                     | Natural Language
                     |
                     v
              +--------------+
              |   FastAPI    |
              |   /chat      |
              +--------------+
                     |
                     v
              Message Matching
               /            \
              /              \
             v                v
    Terraform Command       Ollama
             |                |
             v                v
     +---------------+   +------------+
     | Terraform CLI |   |   Ollama   |
     +---------------+   | llama3.2   |
             |           +------------+
             v
     Terraform Workspace
3. Project Structure

The basic project contains one Python file:

Basic_terraform_template/
│
├── terraform_agent.py
│
└── README.md

The main application is:

terraform_agent.py
4. Configuration

The application contains three important configuration values:

TERRAFORM_WORKSPACE = (
    "/Users/arpitchouksey/Documents/PersonalProjects/"
    "ofcprodapigateway/workspace/workspaces-module/networking-testing"
)

OLLAMA_URL = "http://localhost:11434/api/generate"

OLLAMA_MODEL = "llama3.2"
Terraform Workspace

This is the directory where Terraform commands are executed.

For example:

/Users/arpitchouksey/Documents/PersonalProjects/
ofcprodapigateway/workspace/workspaces-module/networking-testing

The Python application uses this directory as the cwd when executing Terraform.

Ollama URL
http://localhost:11434/api/generate

This assumes Ollama is running locally.

Ollama Model
llama3.2

The model receives user prompts that are not recognized as Terraform commands.

5. FastAPI Application

The application is created using:

app = FastAPI(title="Terraform Agent")

The API accepts JSON requests using:

class ChatRequest(BaseModel):
    message: str

Example request:

{
  "message": "terraform init"
}
6. Terraform Init Tool

The first tool is:

def terraform_init():

It executes:

terraform init

using Python:

result = subprocess.run(
    ["terraform", "init"],
    cwd=TERRAFORM_WORKSPACE,
    capture_output=True,
    text=True
)
Flow
User
 |
 | "terraform init"
 v
/chat
 |
 v
terraform_init()
 |
 v
subprocess.run()
 |
 v
terraform init
 |
 v
Terraform Workspace

The command output is returned to the API.

7. Terraform Plan Tool

The second tool is:

def terraform_plan():

It executes:

terraform plan

using:

result = subprocess.run(
    ["terraform", "plan"],
    cwd=TERRAFORM_WORKSPACE,
    capture_output=True,
    text=True
)

The output is returned to the user.

For example, Terraform may return:

Plan: 7 to add, 0 to change, 0 to destroy.
8. Ollama Integration

Ollama is used as the fallback natural-language component.

The function is:

def ask_ollama(prompt):

It sends the user's message to:

http://localhost:11434/api/generate

with:

{
    "model": "llama3.2",
    "prompt": prompt,
    "stream": False
}

The response is then extracted using:

return response.json()["response"]
9. Chat Endpoint

The main API endpoint is:

POST /chat

The function is:

@app.post("/chat")
def chat(request: ChatRequest):

The user's message is converted to lowercase:

message = request.message.lower()

The application then determines which tool should be executed.

10. Natural Language Tool Selection

The current implementation uses simple keyword matching.

For Terraform Init:

if (
    "terraform init" in message
    or "initialize terraform" in message
    or "initialize terraform project" in message
):

Therefore, these messages can trigger the same tool:

terraform init
initialize terraform
initialize terraform project

The selected tool is:

terraform_init
11. Terraform Plan Detection

Similarly, the application checks:

if (
    "terraform plan" in message
    or "run terraform plan" in message
    or "show terraform plan" in message
    or "create terraform plan" in message
):

Examples:

terraform plan
run terraform plan
show terraform plan
create terraform plan

All of these execute:

terraform_plan()
12. Ollama Fallback

If the message does not match either Terraform tool, the request is sent to Ollama:

answer = ask_ollama(request.message)

The response contains:

{
  "user_message": "your question",
  "tool": "ollama",
  "response": "..."
}

Therefore, the basic decision flow is:

                 User Message
                      |
                      v
                /chat endpoint
                      |
              +-------+-------+
              |               |
       Is it Terraform?       |
          /       \            |
        YES       NO            |
         |         |            |
         v         v            v
    Terraform    Ollama      Ollama
      Tool       Response
13. Running the Project
Step 1 — Install Python dependencies

Create a virtual environment:

python3 -m venv venv

Activate it:

source venv/bin/activate

Install required packages:

pip install fastapi uvicorn requests
14. Start Ollama

Make sure Ollama is running.

Check:

ollama list

Make sure the required model exists:

ollama list

If llama3.2 is not available:

ollama pull llama3.2
15. Start FastAPI

From the directory containing terraform_agent.py:

uvicorn terraform_agent:app --reload --port 8000

You should see:

Uvicorn running on http://127.0.0.1:8000
16. Test Terraform Init

Use:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"terraform init"}'

You can also test natural language:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"initialize terraform"}'

Expected behavior:

FastAPI
   |
   v
terraform_init()
   |
   v
terraform init
   |
   v
Terraform output
17. Test Terraform Plan

Run:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"terraform plan"}'

Or:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"show terraform plan"}'
18. Test Ollama

Send a message that does not match the Terraform commands:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"What is Terraform?"}'

The application sends the request to:

Ollama
  |
  v
llama3.2
  |
  v
Natural-language response
19. Example Complete Flow
User:
initialize terraform project
FastAPI receives:
{
  "message": "initialize terraform project"
}
Agent detects:
terraform_init
Python executes:
terraform init
Response:
{
  "user_message": "initialize terraform project",
  "tool": "terraform_init",
  "result": {
    "status": "success",
    "tool": "terraform_init",
    "output": "Terraform has been successfully initialized!"
  }
}
20. Important Concept

This is a basic interviewer-friendly Agent implementation.

The architecture is intentionally simple:

Natural Language
       |
       v
   FastAPI
       |
       v
Simple Tool Router
       |
       +----------------+
       |                |
       v                v
Terraform Tools      Ollama
       |
       +------+
       |      |
       v      v
     init   plan

It demonstrates the fundamental Agent pattern:

User Request
     ↓
Understand Intent
     ↓
Select Tool
     ↓
Execute Tool
     ↓
Return Result

The next natural enhancement would be replacing the simple if-based routing with an LLM/tool-calling approach and then adding additional Terraform tools such as validate, show, drift, and apply.
