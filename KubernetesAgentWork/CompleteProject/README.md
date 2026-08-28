# Kubernetes Agent --- Frontend + Backend

A local Kubernetes Agent project with a React/Nginx frontend and FastAPI
backend. The backend receives natural-language requests, selects the
appropriate Kubernetes tool, and performs operations against Docker
Desktop Kubernetes.

## Architecture

``` text
Browser :3000
   |
   v
React + Nginx Frontend
   |
   | POST /agent/chat
   v
FastAPI Backend :8000
   |
   v
Agent / Tool Selection
   |
   +--> create_namespace
   +--> create_pod
   +--> create_deployment
   +--> scale_deployment
   +--> delete_deployment
   +--> get_pod_logs
   |
   v
Docker Desktop Kubernetes
```

## Project Structure

``` text
KubernetesAgent/
├── app/
│   ├── main.py
│   └── tools/
│       ├── namespace/
│       ├── pods/
│       ├── deployments/
│       └── troubleshooting/
├── Dockerfile
└── requirements.txt

frontend/
├── src/
├── public/
├── Dockerfile
├── nginx.conf
└── package.json
```

## Prerequisites

-   Docker Desktop
-   Docker Desktop Kubernetes enabled
-   Python 3.x for local backend development
-   `kubectl`

Check Kubernetes:

``` bash
kubectl config current-context
kubectl get nodes
```

Expected context:

``` text
docker-desktop
```

## Backend

Go to the backend:

``` bash
cd KubernetesAgent
```

Optional local virtual environment:

``` bash
source venv/bin/activate
pip install -r requirements.txt
```

Run locally:

``` bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

FastAPI:

``` text
http://127.0.0.1:8000
```

Swagger:

``` text
http://127.0.0.1:8000/docs
```

### Build backend image

``` bash
docker build -t kubernetes-agent .
```

Remove an old container:

``` bash
docker rm -f kubernetes-agent 2>/dev/null || true
```

Run:

``` bash
docker run -d   --name kubernetes-agent   -p 8000:8000   kubernetes-agent
```

Verify:

``` bash
docker ps
docker logs kubernetes-agent
```

Verify Kubernetes access from inside the container:

``` bash
docker exec -it kubernetes-agent kubectl config current-context
docker exec -it kubernetes-agent kubectl get nodes
```

For a direct Docker Desktop Kubernetes API test:

``` bash
docker exec -it kubernetes-agent curl -k https://kubernetes.docker.internal:6443/version
```

The `-k` is useful for this local connectivity test when the container
does not have the required local CA certificate.

## Frontend

The frontend is a React application served by Nginx.

Go to the frontend:

``` bash
cd frontend
```

Build:

``` bash
docker build -t kubernetes-agent-frontend .
```

Remove an old container:

``` bash
docker rm -f kubernetes-agent-frontend 2>/dev/null || true
```

Run:

``` bash
docker run -d   --name kubernetes-agent-frontend   -p 3000:80   kubernetes-agent-frontend
```

Verify Nginx:

``` bash
curl -I http://localhost:3000
```

Open:

``` text
http://localhost:3000
```

The port mapping is:

``` text
localhost:3000 -> container:80
```

## Backend API Testing

All examples use:

``` text
POST http://127.0.0.1:8000/agent/chat
```

### Create namespace

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"create namespace agent-test"}'
```

Verify:

``` bash
kubectl get namespace agent-test
```

### Create pod

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"create pod agent-nginx using image nginx in namespace default"}'
```

Verify:

``` bash
kubectl get pod agent-nginx
```

Important: the current `create_pod` function accepts `name`, `image`,
and `namespace`; it does not accept `replicas`. Use a Deployment when
replicas are required.

### Create deployment

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"create deployment agent-nginx using image nginx with 2 replicas in namespace default"}'
```

Verify:

``` bash
kubectl get deployment agent-nginx
kubectl get pods
```

### Scale deployment

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"scale deployment agent-nginx to 3 replicas in namespace default"}'
```

Verify:

``` bash
kubectl get deployment agent-nginx
```

### Get pod logs

First find the pod:

``` bash
kubectl get pods
```

Then:

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"show logs of pod <POD_NAME> in namespace default"}'
```

For a known pod:

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"show logs of pod agent-nginx in namespace default"}'
```

### Delete deployment

``` bash
curl -X POST http://127.0.0.1:8000/agent/chat -H "Content-Type: application/json" -d '{"message":"delete deployment agent-nginx from namespace default"}'
```

Verify:

``` bash
kubectl get deployment agent-nginx
```

## UI Test Prompts

Open:

``` text
http://localhost:3000
```

Then test:

``` text
create namespace test-agent-ui
```

``` text
create pod nginx-test using image nginx in namespace test-agent-ui
```

``` text
create deployment nginx-deployment using image nginx with 2 replicas in namespace test-agent-ui
```

``` text
scale deployment nginx-deployment to 3 replicas in namespace test-agent-ui
```

``` text
show logs of pod nginx-test in namespace test-agent-ui
```

``` text
delete deployment nginx-deployment from namespace test-agent-ui
```

Verify resources with:

``` bash
kubectl get all -n test-agent-ui
```

## Main Request Flow

``` text
User
  |
  v
Frontend chat UI
  |
  | JSON: {"message":"..."}
  v
POST /agent/chat
  |
  v
FastAPI
  |
  v
Agent decides tool
  |
  v
Selected Python tool
  |
  v
Kubernetes API / kubectl
  |
  v
Docker Desktop Kubernetes
  |
  v
Tool result
  |
  v
FastAPI response
  |
  v
Frontend result card
```

The tool metadata tells the agent what each function can do and which
arguments it accepts. The selected tool is then called with the
extracted arguments.

## Troubleshooting

### Unknown tool

If you see:

``` text
Unknown tool: create_pod
```

Check that the tool:

-   exists under `app/tools/`
-   is imported/discovered by the tool loader
-   has `is_agent_tool = True`
-   has `tool_name`
-   has `tool_description`

### Unexpected keyword argument

If you see:

``` text
create_pod() got an unexpected keyword argument 'replicas'
```

the agent selected `create_pod` but passed `replicas`, which the current
function does not accept. Use `create_deployment` for replica-based
workloads.

### Backend cannot reach Kubernetes

Run:

``` bash
docker exec -it kubernetes-agent kubectl config current-context
docker exec -it kubernetes-agent kubectl get nodes
```

The backend container's kubeconfig should use Docker Desktop's
Kubernetes endpoint:

``` text
https://kubernetes.docker.internal:6443
```

### Frontend does not open

Run:

``` bash
docker ps
docker logs kubernetes-agent-frontend
curl -I http://localhost:3000
```

Expected:

``` text
HTTP/1.1 200 OK
Server: nginx/...
```

## Cleanup

Remove project containers:

``` bash
docker rm -f kubernetes-agent kubernetes-agent-frontend
```

Remove project images:

``` bash
docker rmi kubernetes-agent kubernetes-agent-frontend
```

Remove a Kubernetes test namespace and everything inside it:

``` bash
kubectl delete namespace test-agent-ui
```

## Quick Start

### Terminal 1 --- Backend

``` bash
cd KubernetesAgent
docker build -t kubernetes-agent .
docker rm -f kubernetes-agent 2>/dev/null || true
docker run -d --name kubernetes-agent -p 8000:8000 kubernetes-agent
docker exec -it kubernetes-agent kubectl get nodes
```

### Terminal 2 --- Frontend

``` bash
cd frontend
docker build -t kubernetes-agent-frontend .
docker rm -f kubernetes-agent-frontend 2>/dev/null || true
docker run -d --name kubernetes-agent-frontend -p 3000:80 kubernetes-agent-frontend
curl -I http://localhost:3000
```

Then open:

``` text
http://localhost:3000
```
