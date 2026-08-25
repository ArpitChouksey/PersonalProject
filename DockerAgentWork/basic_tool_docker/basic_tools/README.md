LLM Dockerfile Generator
Overview

This is a simple FastAPI + LLM Dockerfile Generator project.

The application accepts a natural-language request from the user, sends the request to a local Llama 3.2 model running through Ollama, generates a Dockerfile based on the requirements, and saves the generated Dockerfile into the user's Downloads folder.

Example

User:

Create a production Java Dockerfile using eclipse-temurin:21-jdk.
Use /app as the working directory.
Copy app.jar into /app.
Expose port 8080.
Start it using java -jar app.jar.

The LLM generates:

FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY app.jar /app

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]

The file is saved as:

~/Downloads/llm_docker_images/Dockerfile-generated
Architecture
User
  |
  | Natural-language Dockerfile request
  v
FastAPI
  |
  v
Ollama
  |
  v
Llama 3.2
  |
  | Generated Dockerfile
  v
Python Application
  |
  v
~/Downloads/llm_docker_images/
  |
  v
Dockerfile-generated
Project Structure
llm_docker_images/
│
└── main.py

The application is intentionally kept in a single Python file for simplicity.

Technologies Used
Python
FastAPI
Pydantic
Requests
Ollama
Llama 3.2
Prerequisites
Python

Check:

python3 --version
Ollama

Check:

ollama --version

Check the model:

ollama list

If llama3.2 is not available:

ollama pull llama3.2
1. Create Virtual Environment

Go to the project directory:

cd <project-directory>

Create the virtual environment:

python3 -m venv .venv

Activate it:

source .venv/bin/activate
2. Install Dependencies
pip install fastapi uvicorn requests
3. Start Ollama

Run:

ollama run llama3.2

Keep Ollama running.

The application connects to:

http://localhost:11434/api/generate
4. Start FastAPI

Open another terminal:

source .venv/bin/activate

Run:

python -m uvicorn main:app --reload --port 8000

The API will run on:

http://127.0.0.1:8000
5. Test the Application
Basic Java Dockerfile
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"Create a Dockerfile for Java"}'

Expected response:

{
  "status": "SUCCESS",
  "file": "/Users/<user>/Downloads/llm_docker_images/Dockerfile-generated",
  "dockerfile": "FROM eclipse-temurin:17-jdk\n..."
}
6. Test With Specific Requirements
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{
  "message": "Create a production Java Dockerfile using eclipse-temurin:21-jdk. Use /app as the working directory. Copy app.jar into /app. Expose port 8080. Start it using java -jar app.jar."
}'

The LLM should generate a Dockerfile matching those requirements.

7. Check Generated File

The application creates:

~/Downloads/llm_docker_images/

and saves:

Dockerfile-generated

Check it:

cat ~/Downloads/llm_docker_images/Dockerfile-generated
8. Example Generated Dockerfile

For the Java request, the generated file can look like:

FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY app.jar /app

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
How It Works
Step 1 — User Request

The user sends:

Create a production Java Dockerfile using Java 21.
Step 2 — FastAPI

FastAPI receives the request:

@app.post("/chat")
def chat(request: ChatRequest):
Step 3 — LLM

The request is sent to Ollama:

response = requests.post(
    OLLAMA_URL,
    json={
        "model": MODEL,
        "prompt": prompt,
        "stream": False
    }
)
Step 4 — Dockerfile Generation

The LLM generates only the Dockerfile.

Step 5 — File Creation

Python creates:

~/Downloads/llm_docker_images/Dockerfile-generated
Step 6 — API Response

The API returns both:

Generated file path
Generated Dockerfile content
Important Prompt Behavior

The application instructs the LLM:

Generate ONLY the Dockerfile.
Do not return JSON.
Do not use markdown code fences.
Do not add explanations.
Create a valid Dockerfile based on the user's requirements.

This keeps the LLM output suitable for directly writing into a Dockerfile.

Error Handling

If Ollama is unavailable, the model is missing, or file creation fails, the API returns:

{
  "status": "ERROR",
  "message": "error details"
}
Interview Explanation

You can explain this project in a few lines:

"I created a FastAPI service that accepts natural-language Dockerfile requirements. The request is sent to a local Llama 3.2 model through Ollama. The LLM generates the Dockerfile according to the user's requirements, and the Python application saves the generated Dockerfile to a local Downloads directory and returns the file path and content."

Core flow
Natural Language
       ↓
     FastAPI
       ↓
     Ollama
       ↓
    Llama 3.2
       ↓
 Dockerfile Content
       ↓
 Python File Write
       ↓
 Dockerfile-generated
