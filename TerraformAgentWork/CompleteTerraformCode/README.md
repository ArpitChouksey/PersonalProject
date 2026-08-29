# Terraform Agent -- Agentic Infrastructure Assistant

A Dockerized Terraform Agent with a React frontend and FastAPI backend.

The project provides a chat-based UI where a user can connect a
Terraform workspace and ask questions such as:

-   `terraform init`
-   `terraform plan`
-   `explain terraform`
-   `what resources will be created?`
-   `is there any drift?`
-   `explain the plan`

The agent executes Terraform operations inside a backend container and
converts Terraform output into a structured, easier-to-understand UI.

------------------------------------------------------------------------

## 1. Project Architecture

``` text
                         Browser
                            |
                            | http://localhost:5173
                            v
                 +----------------------+
                 |   React Frontend     |
                 |   Terraform UI       |
                 |   Nginx Container    |
                 |   Port 5173 -> 80    |
                 +----------+-----------+
                            |
                            | HTTP POST /agent/chat
                            v
                 +----------------------+
                 |   FastAPI Backend    |
                 |   Terraform Agent    |
                 |   Container          |
                 |   Port 8000          |
                 +----------+-----------+
                            |
              +-------------+-------------+
              |                           |
              v                           v
      Terraform CLI                  AWS Credentials
      terraform init/plan            ~/.aws (read-only)
              |
              v
      Mounted Terraform Workspace
              |
              v
      main.tf / variables.tf /
      outputs.tf / tfplan
```

------------------------------------------------------------------------

## 2. Main Components

  -----------------------------------------------------------------------
  Component              Technology             Purpose
  ---------------------- ---------------------- -------------------------
  Frontend               React + Vite           Chat UI and Terraform
                                                result visualization

  Web Server             Nginx                  Serves the production
                                                React build

  Backend                FastAPI + Python       Receives chat requests
                                                and runs the agent

  Agent                  Python Agent           Selects/executes
                                                Terraform tools

  Terraform              Terraform CLI          Performs init, plan and
                                                related operations

  Cloud                  AWS                    Terraform
                                                provider/infrastructure
                                                target

  Containerization       Docker                 Packages frontend and
                                                backend

  Workspace              Host-mounted directory Terraform configuration
                                                used by the agent
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 3. Frontend

The frontend is the React application.

Typical structure:

``` text
terraform-ui/
├── src/
│   ├── App.jsx
│   ├── ...
├── public/
├── package.json
├── Dockerfile
├── nginx.conf
└── ...
```

The frontend provides:

### Workspace Section

The user enters/selects the Terraform workspace from the UI.

The UI sends the workspace information to the backend instead of
requiring the user to repeatedly provide it in every chat message.

### Chat Section

The user can ask:

``` text
what resources will be created?
```

or:

``` text
is there any drift?
```

The backend performs the Terraform operation and returns structured
data.

### Terraform Plan Visualization

Instead of showing only:

``` text
7 to add, 0 to change, 0 to destroy
```

the UI can show:

``` text
CREATE
aws_vpc.main
aws_subnet.public
aws_subnet.private
aws_internet_gateway.this
...
```

This makes the result understandable without reading raw Terraform
output.

------------------------------------------------------------------------

# 4. Backend

The backend is a FastAPI application.

Typical structure:

``` text
terraform-agent/
├── app/
│   ├── main.py
│   ├── ...
├── requirements.txt
├── Dockerfile
└── ...
```

The backend exposes the chat API.

Example:

``` text
POST /agent/chat
```

The request contains the user's message and workspace information.

The backend then:

1.  Receives the request.
2.  Resolves the configured workspace.
3.  Runs the appropriate Terraform agent/tool.
4.  Captures Terraform output.
5.  Parses Terraform plan information.
6.  Returns structured JSON.
7.  Frontend converts the response into a readable UI.

------------------------------------------------------------------------

# 5. Workspace Handling

The important design is that the Terraform workspace should not have to
be typed repeatedly.

The frontend can establish the workspace once.

Conceptually:

``` text
User
 |
 | Connect Workspace
 v
React UI
 |
 | workspace
 v
FastAPI
 |
 | store/use workspace
 v
Terraform Agent
 |
 | terraform command
 v
Workspace
```

Inside Docker, the host workspace is mounted into the backend container.

For example:

``` text
Host:
~/.../networking-testing

        |
        | Docker volume
        v

Container:
/terraform/workspace
```

The exact host path can be changed when starting the container.

Do not hardcode a developer-specific path into the application.

------------------------------------------------------------------------

# 6. AWS Credentials

The backend container can use the host AWS CLI configuration.

Example Docker volume:

``` bash
-v ~/.aws:/root/.aws:ro
```

This mounts the host AWS configuration read-only.

Verify AWS access from the backend container:

``` bash
docker exec -it terraform-agent aws sts get-caller-identity
```

If the AWS CLI is not installed in the image, verify the
credentials/configuration using the AWS tooling already included by the
backend image.

------------------------------------------------------------------------

# 7. Build Backend Image

Go to the backend project directory:

``` bash
cd /path/to/terraform-agent
```

Build:

``` bash
docker build -t terraform-agent .
```

------------------------------------------------------------------------

# 8. Run Backend Container

First remove an old container if necessary:

``` bash
docker rm -f terraform-agent
```

Then run:

``` bash
docker run -d \
  --name terraform-agent \
  -p 8000:8000 \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.aws:/root/.aws:ro \
  -v "/YOUR/HOST/TERRAFORM_WORKSPACE:/terraform/workspace" \
  terraform-agent
```

Replace:

``` text
/YOUR/HOST/TERRAFORM_WORKSPACE
```

with the Terraform directory you want to use.

Example:

``` bash
-v "/Users/arpitchouksey/Documents/PersonalProjects/ofcprodapigateway/workspace/workspaces-module/networking-testing:/terraform/workspace"
```

The important point is:

``` text
Host path
    ↓
/terraform/workspace
```

inside the container.

------------------------------------------------------------------------

# 9. Verify Backend

Check the container:

``` bash
docker ps
```

Expected:

``` text
terraform-agent
```

Check logs:

``` bash
docker logs -f terraform-agent
```

Expected:

``` text
Application startup complete.
Uvicorn running on http://0.0.0.0:8000
```

Check the API from the host:

``` bash
curl http://localhost:8000
```

If the application has a health endpoint, use:

``` bash
curl http://localhost:8000/health
```

------------------------------------------------------------------------

# 10. Verify Workspace Inside Container

This is an important troubleshooting step.

Run:

``` bash
docker exec -it terraform-agent ls -la /terraform/workspace
```

You should see files such as:

``` text
main.tf
variables.tf
outputs.tf
tfplan
```

You can also enter the container:

``` bash
docker exec -it terraform-agent sh
```

Then:

``` bash
ls -la /terraform/workspace
```

Exit:

``` bash
exit
```

If the files are not present, the Docker volume mapping is incorrect.

------------------------------------------------------------------------

# 11. Frontend Build

Go to the frontend:

``` bash
cd /path/to/terraform-ui
```

Install dependencies if running locally:

``` bash
npm install
```

Build the React application:

``` bash
npm run build
```

For Docker production deployment:

``` bash
docker build -t terraform-agent-ui .
```

------------------------------------------------------------------------

# 12. Run Frontend Container

If an old container exists:

``` bash
docker rm -f terraform-agent-ui
```

Run:

``` bash
docker run -d \
  --name terraform-agent-ui \
  -p 5173:80 \
  terraform-agent-ui
```

Open:

``` text
http://localhost:5173
```

------------------------------------------------------------------------

# 13. Frontend Logs

Check:

``` bash
docker logs -f terraform-agent-ui
```

Nginx should show something similar to:

``` text
Configuration complete; ready for start up
start worker processes
```

------------------------------------------------------------------------

# 14. Complete Startup Sequence

Use two terminals.

## Terminal 1 -- Backend

``` bash
cd /path/to/terraform-agent
```

``` bash
docker rm -f terraform-agent 2>/dev/null || true
```

``` bash
docker build -t terraform-agent .
```

``` bash
docker run -d \
  --name terraform-agent \
  -p 8000:8000 \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.aws:/root/.aws:ro \
  -v "/YOUR/HOST/TERRAFORM_WORKSPACE:/terraform/workspace" \
  terraform-agent
```

Check:

``` bash
docker logs -f terraform-agent
```

------------------------------------------------------------------------

## Terminal 2 -- Frontend

``` bash
cd /path/to/terraform-ui
```

``` bash
docker rm -f terraform-agent-ui 2>/dev/null || true
```

``` bash
docker build -t terraform-agent-ui .
```

``` bash
docker run -d \
  --name terraform-agent-ui \
  -p 5173:80 \
  terraform-agent-ui
```

Open:

``` text
http://localhost:5173
```

------------------------------------------------------------------------

# 15. Recommended Testing Flow

After both containers are running:

### Step 1

Open:

``` text
http://localhost:5173
```

### Step 2

Connect the Terraform workspace.

### Step 3

Run:

``` text
terraform init
```

### Step 4

Ask:

``` text
terraform plan
```

### Step 5

Ask:

``` text
what resources will be created?
```

The response should be structured instead of displaying only raw
Terraform terminal output.

### Step 6

Ask:

``` text
is there any drift?
```

The agent should explain changes detected between the Terraform
configuration/state and the actual infrastructure.

### Step 7

Ask:

``` text
explain the plan
```

The UI should summarize:

``` text
Terraform Plan

Create: 7
Modify: 0
Replace: 0
Destroy: 0
Total: 7
```

and then list the actual resources.

Example:

  Action   Resource                    Type
  -------- --------------------------- ------------------
  CREATE   aws_vpc.main                VPC
  CREATE   aws_subnet.public           Subnet
  CREATE   aws_subnet.private          Subnet
  CREATE   aws_internet_gateway.this   Internet Gateway

The exact resources depend on the Terraform workspace.

------------------------------------------------------------------------

# 16. Why Structured Plan Output Was Added

Raw Terraform output is designed primarily for terminal users.

For example:

``` text
Plan: 7 to add, 0 to change, 0 to destroy.
```

This tells us the number of changes but not immediately what those
changes mean.

The structured response provides two levels:

### Summary

``` text
CREATE   7
MODIFY   0
REPLACE  0
DESTROY  0
TOTAL    7
```

### Resource Details

``` text
aws_vpc.main
aws_subnet.public
aws_subnet.private
aws_route_table.workspaces
...
```

This is much easier for a user to understand.

------------------------------------------------------------------------

# 17. Drift Detection

Drift and planned changes are related but different concepts.

A normal plan can show resources Terraform intends to create or modify.

A drift check is intended to identify differences between:

``` text
Terraform configuration/state
          VS
Actual infrastructure
```

The UI should therefore explain the detected change rather than simply
returning a number.

Example:

``` text
Drift detected

Resource:
aws_security_group.example

Change:
Ingress rule differs from Terraform configuration.

Action:
Review the resource before applying changes.
```

------------------------------------------------------------------------

# 18. Useful Docker Commands

### List running containers

``` bash
docker ps
```

### List all containers

``` bash
docker ps -a
```

### Backend logs

``` bash
docker logs -f terraform-agent
```

### Frontend logs

``` bash
docker logs -f terraform-agent-ui
```

### Enter backend container

``` bash
docker exec -it terraform-agent sh
```

### Inspect mounted workspace

``` bash
docker exec -it terraform-agent ls -la /terraform/workspace
```

### Stop backend

``` bash
docker stop terraform-agent
```

### Remove backend

``` bash
docker rm -f terraform-agent
```

### Stop frontend

``` bash
docker stop terraform-agent-ui
```

### Remove frontend

``` bash
docker rm -f terraform-agent-ui
```

------------------------------------------------------------------------

# 19. Rebuild After Code Changes

## Backend changes

``` bash
docker rm -f terraform-agent 2>/dev/null || true
docker build -t terraform-agent .
docker run -d \
  --name terraform-agent \
  -p 8000:8000 \
  --add-host=host.docker.internal:host-gateway \
  -v ~/.aws:/root/.aws:ro \
  -v "/YOUR/HOST/TERRAFORM_WORKSPACE:/terraform/workspace" \
  terraform-agent
```

## Frontend changes

``` bash
docker rm -f terraform-agent-ui 2>/dev/null || true
docker build -t terraform-agent-ui .
docker run -d \
  --name terraform-agent-ui \
  -p 5173:80 \
  terraform-agent-ui
```

------------------------------------------------------------------------

# 20. Common Problems

## Problem: Container name already in use

Error:

``` text
Conflict. The container name "/terraform-agent-ui" is already in use
```

Fix:

``` bash
docker rm -f terraform-agent-ui
```

Then run the container again.

------------------------------------------------------------------------

## Problem: Frontend says "Failed to fetch"

Check backend:

``` bash
docker ps
```

Then:

``` bash
docker logs terraform-agent
```

Confirm:

``` text
Uvicorn running on http://0.0.0.0:8000
```

Also verify:

``` bash
curl http://localhost:8000
```

------------------------------------------------------------------------

## Problem: Terraform path does not exist inside container

Check:

``` bash
docker exec -it terraform-agent ls -la /terraform/workspace
```

If empty/wrong, verify the `-v` mapping in `docker run`.

------------------------------------------------------------------------

## Problem: Terraform works on host but not inside Docker

Check:

``` bash
docker exec -it terraform-agent terraform version
```

Then:

``` bash
docker exec -it terraform-agent ls -la /terraform/workspace
```

Also verify AWS credentials:

``` bash
docker exec -it terraform-agent aws sts get-caller-identity
```

------------------------------------------------------------------------

# 21. Important Design Principle

Do not put a developer-specific path directly into the Python or React
source code.

Avoid:

``` text
/Users/arpitchouksey/...
```

inside application logic.

Instead use:

``` text
UI
 ↓
Workspace selected by user
 ↓
Backend workspace configuration
 ↓
Docker mounted workspace
 ↓
Terraform
```

This makes the project portable between developers, machines and
environments.

------------------------------------------------------------------------

# 22. Current Project Goal

The Terraform Agent is being built as one part of a larger Agentic
Infrastructure project.

The broader architecture can later contain:

``` text
                 Agentic Infrastructure Assistant
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
     Docker Agent        Terraform Agent     Kubernetes Agent
          |                   |                   |
          +-------------------+-------------------+
                              |
                              v
                         MCP Layer
                              |
                              v
                     Common Infrastructure
                         Tool Interface
```

The long-term objective is to expose infrastructure operations through a
common tool/MCP architecture so that Docker, Terraform and Kubernetes
agents can work through the same interface.

------------------------------------------------------------------------

# 23. Quick Reference

  Item                  Value
  --------------------- -------------------------
  Frontend              React + Vite
  Frontend server       Nginx
  Frontend port         `5173`
  Backend               FastAPI
  Backend port          `8000`
  Frontend container    `terraform-agent-ui`
  Backend container     `terraform-agent`
  Frontend image        `terraform-agent-ui`
  Backend image         `terraform-agent`
  Backend API           `/agent/chat`
  Container workspace   `/terraform/workspace`
  AWS credentials       `~/.aws` → `/root/.aws`
  Frontend URL          `http://localhost:5173`
  Backend URL           `http://localhost:8000`

------------------------------------------------------------------------

# 24. Final Run Checklist

Before testing, verify:

``` bash
docker ps
```

You should have:

``` text
terraform-agent
terraform-agent-ui
```

Then verify backend:

``` bash
docker logs terraform-agent
```

Verify workspace:

``` bash
docker exec -it terraform-agent ls -la /terraform/workspace
```

Verify frontend:

``` text
http://localhost:5173
```

Then:

``` text
Connect Workspace
        ↓
terraform init
        ↓
terraform plan
        ↓
what resources will be created?
        ↓
is there any drift?
        ↓
explain the plan
```

The expected final experience is a chat-based Terraform assistant that
presents both the **high-level plan summary** and the **actual
resources/actions**, rather than only showing raw terminal output.

------------------------------------------------------------------------

# 25. Proper Code Structure

A clean separation between UI, API communication, agent logic, Terraform
tools and infrastructure execution should be maintained.

Recommended structure:

``` text
PersonalProjects/
└── terraform-agent-project/
    │
    ├── terraform-agent/                 # Backend
    │   ├── app/
    │   │   ├── main.py                  # FastAPI application / API routes
    │   │   ├── agent.py                 # Agent decision/orchestration logic
    │   │   ├── tools/
    │   │   │   ├── terraform_init.py   # terraform init
    │   │   │   ├── terraform_plan.py   # terraform plan
    │   │   │   ├── terraform_drift.py  # drift checking
    │   │   │   └── terraform_explain.py# plan explanation/parser
    │   │   ├── services/
    │   │   │   ├── terraform_service.py # Terraform command execution
    │   │   │   └── workspace_service.py # Workspace handling
    │   │   └── schemas/
    │   │       └── models.py             # Request/response models
    │   │
    │   ├── requirements.txt
    │   ├── Dockerfile
    │   └── ...
    │
    └── terraform-ui/                    # Frontend
        ├── src/
        │   ├── App.jsx                   # Main UI
        │   ├── components/
        │   │   ├── Workspace.jsx         # Workspace connection UI
        │   │   ├── Chat.jsx              # Chat interface
        │   │   ├── Message.jsx           # Chat message
        │   │   ├── PlanSummary.jsx       # Create/modify/replace/destroy
        │   │   └── ResourceTable.jsx     # Resource details table
        │   ├── services/
        │   │   └── api.js                # Backend API calls
        │   └── styles/
        │       └── ...
        │
        ├── package.json
        ├── Dockerfile
        ├── nginx.conf
        └── ...
```

The exact filenames can differ from the current implementation, but this
is the recommended logical separation as the project grows.

------------------------------------------------------------------------

# 26. End-to-End Code Flow

The complete request flow should be understood as:

``` text
USER
 |
 | 1. Enter / select workspace
 | 2. Ask: "what resources will be created?"
 v
React Frontend
 |
 | Workspace + message
 v
API Service
 |
 | POST /agent/chat
 v
FastAPI Backend
 |
 v
Agent
 |
 | Understand user intent
 | Select Terraform operation/tool
 v
Terraform Tool
 |
 | Example:
 | terraform plan
 | terraform show
 v
Terraform Service
 |
 | Execute command
 | cwd = selected workspace
 v
Terraform CLI
 |
 v
Terraform Workspace
 |
 | main.tf
 | variables.tf
 | outputs.tf
 | state
 v
Terraform Output
 |
 v
Parser / Explanation Layer
 |
 | Convert raw output into:
 | - summary
 | - resources
 | - actions
 | - drift information
 v
Structured JSON Response
 |
 v
React Frontend
 |
 | Render readable UI
 v
USER
```

------------------------------------------------------------------------

# 27. Detailed Backend Code Flow

## Step 1 -- API Request

The frontend sends a request similar to:

``` json
{
  "message": "what resources will be created?",
  "workspace": "/terraform/workspace"
}
```

The API endpoint receives the request:

``` text
POST /agent/chat
```

------------------------------------------------------------------------

## Step 2 -- FastAPI

`main.py` is responsible for receiving the HTTP request and passing it
to the agent.

Logical flow:

``` text
main.py
   |
   v
validate request
   |
   v
agent.chat(...)
```

The API layer should not contain all Terraform command execution logic.

------------------------------------------------------------------------

## Step 3 -- Agent

The agent determines what the user is asking.

Example:

``` text
User:
"what resources will be created?"
```

The agent maps the request to the appropriate Terraform operation:

``` text
what resources will be created?
             |
             v
       terraform plan
             |
             v
     terraform_explain
```

Another example:

``` text
User:
"is there any drift?"
             |
             v
       drift operation
```

The agent therefore acts as the orchestration layer.

------------------------------------------------------------------------

# 28. Terraform Tool Layer

Terraform operations should be separated into tools.

Example:

``` text
tools/
├── terraform_init.py
├── terraform_plan.py
├── terraform_drift.py
└── terraform_explain.py
```

Conceptually:

``` text
terraform_init()
       |
       v
terraform init


terraform_plan()
       |
       v
terraform plan


terraform_drift()
       |
       v
refresh / plan analysis


terraform_explain_plan()
       |
       v
terraform show / parse plan
```

This makes each operation independently testable and makes it easier to
expose the same tools later through MCP.

------------------------------------------------------------------------

# 29. Terraform Service Layer

The tool should not duplicate low-level subprocess logic.

Instead:

``` text
Terraform Tool
      |
      v
Terraform Service
      |
      v
subprocess
      |
      v
terraform CLI
```

The service is responsible for common execution behavior:

``` text
command
workspace
environment
timeout
stdout
stderr
return code
```

For example:

``` text
terraform plan
```

should execute with:

``` text
working directory =
selected Terraform workspace
```

This is where dynamic workspace handling becomes important.

------------------------------------------------------------------------

# 30. Workspace Flow

The workspace should flow through the application instead of being
hardcoded.

Correct design:

``` text
                 User selects workspace
                         |
                         v
                    React UI
                         |
                         | workspace
                         v
                   FastAPI API
                         |
                         v
                       Agent
                         |
                         v
                 Terraform Service
                         |
                         v
                 Terraform CLI
                         |
                         v
                /terraform/workspace
```

Avoid:

``` python
workspace = "/Users/arpitchouksey/..."
```

inside application code.

The host-specific path belongs in Docker/runtime configuration.

------------------------------------------------------------------------

# 31. Docker Workspace Mapping

The host path is mapped into the container:

``` text
HOST
/Users/.../networking-testing
             |
             | Docker volume
             v
CONTAINER
/terraform/workspace
```

The application should use:

``` text
/terraform/workspace
```

as the container-side workspace.

This allows the same backend image to work with different host
workspaces.

For example:

``` text
Developer A
    host workspace A
          |
          v
/terraform/workspace


Developer B
    host workspace B
          |
          v
/terraform/workspace
```

The Docker image does not need to change.

------------------------------------------------------------------------

# 32. Structured Response Flow

Raw Terraform output:

``` text
Plan: 7 to add, 0 to change, 0 to destroy.
```

should be converted into a structured response.

Conceptually:

``` json
{
  "status": "success",
  "tool": "terraform_explain_plan",
  "workspace": "/terraform/workspace",
  "summary": {
    "create": 7,
    "modify": 0,
    "replace": 0,
    "destroy": 0,
    "total": 7
  },
  "resources": [
    {
      "action": "create",
      "address": "aws_vpc.main",
      "type": "aws_vpc"
    },
    {
      "action": "create",
      "address": "aws_subnet.public",
      "type": "aws_subnet"
    }
  ]
}
```

The important part is that the frontend receives **resource-level
information**, not only the number `7`.

------------------------------------------------------------------------

# 33. Frontend Rendering Flow

The frontend should not have to understand raw Terraform terminal
output.

Instead:

``` text
Backend JSON
     |
     v
App.jsx
     |
     +------------------+
     |                  |
     v                  v
PlanSummary        ResourceTable
     |                  |
     v                  v
7 CREATE           Resource list
0 MODIFY           aws_vpc.main
0 REPLACE          aws_subnet.public
0 DESTROY          aws_subnet.private
```

This keeps presentation separate from Terraform execution.

------------------------------------------------------------------------

# 34. Example UI Flow

User asks:

``` text
what resources will be created?
```

Backend returns:

``` text
CREATE = 7
MODIFY = 0
REPLACE = 0
DESTROY = 0
```

and:

``` text
aws_vpc.main
aws_subnet.public
aws_subnet.private
aws_internet_gateway.this
aws_route_table.workspaces
...
```

Frontend displays:

``` text
Terraform Plan
────────────────────────────────────

CREATE       7
MODIFY       0
REPLACE      0
DESTROY      0
TOTAL        7

Resources to be created
────────────────────────────────────

| Action | Resource                  | Type               |
| CREATE | aws_vpc.main              | aws_vpc            |
| CREATE | aws_subnet.public         | aws_subnet          |
| CREATE | aws_subnet.private        | aws_subnet          |
| CREATE | aws_internet_gateway.this | aws_internet_gateway |
```

This is the preferred user experience over displaying the complete
terminal output.

------------------------------------------------------------------------

# 35. Responsibility of Each Layer

  Layer               Responsibility
  ------------------- -----------------------------------------------
  React UI            User interaction and visualization
  API service         HTTP request/response
  Agent               Understand request and select operation
  Tool                Define a specific Terraform capability
  Terraform service   Execute Terraform commands
  Parser              Convert Terraform output into structured data
  Docker              Runtime isolation and workspace mounting
  Terraform CLI       Actual infrastructure planning/execution
  AWS Provider        Communicate with AWS

A useful rule is:

``` text
UI should not run Terraform.
API should not contain all Terraform logic.
Agent should not contain UI logic.
Terraform tools should not contain presentation code.
```

------------------------------------------------------------------------

# 36. Future MCP Integration

Once the Terraform tools are cleanly separated, MCP can be added above
the tool layer.

Current:

``` text
React
  |
FastAPI
  |
Agent
  |
Terraform Tools
  |
Terraform
```

Future:

``` text
                    React UI
                       |
                    FastAPI
                       |
                     Agent
                       |
                    MCP Client
                       |
              +--------+--------+
              |                 |
              v                 v
          MCP Server       Other MCP Server
              |
      +-------+--------+
      |       |        |
      v       v        v
   Terraform Docker Kubernetes
     Tools    Tools     Tools
```

This means the existing Terraform functionality does not need to be
thrown away. The existing tools can become MCP-exposed capabilities
later.

------------------------------------------------------------------------

# 37. Development Principle

Build the project in layers:

``` text
1. Terraform commands work
          ↓
2. Terraform tools work
          ↓
3. Agent selects tools
          ↓
4. FastAPI exposes agent
          ↓
5. React communicates with API
          ↓
6. Structured Terraform responses
          ↓
7. Dockerize backend
          ↓
8. Dockerize frontend
          ↓
9. Add MCP layer
          ↓
10. Connect Terraform + Docker + Kubernetes agents
```

This keeps debugging simple because each layer can be tested
independently.

------------------------------------------------------------------------

# 38. Final Mental Model

The easiest way to remember the project is:

``` text
                    USER
                     |
                     v
                REACT UI
                     |
                     | HTTP
                     v
                FASTAPI
                     |
                     v
                  AGENT
                     |
             "What does user want?"
                     |
                     v
                  TOOL
                     |
             "Which Terraform
              operation?"
                     |
                     v
             TERRAFORM SERVICE
                     |
                     v
              TERRAFORM CLI
                     |
                     v
                WORKSPACE
                     |
                     v
             RAW TERRAFORM DATA
                     |
                     v
              PARSER / EXPLAINER
                     |
                     v
              STRUCTURED JSON
                     |
                     v
                REACT UI
                     |
                     v
            HUMAN-READABLE RESULT
```

This separation is the foundation for extending the project from a
Terraform Agent into a common **Docker + Terraform + Kubernetes
Agent/MCP platform**.
