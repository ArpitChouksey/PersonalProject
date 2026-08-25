import os
import re

from app.executor import run_command


# ============================================================
# APPLICATION DETECTION
# ============================================================

def detect_application(path="."):
    """
    Detect common application types from files in a directory.

    This is intentionally simple:
    Linux/Python performs detection,
    Docker CLI performs Docker operations.
    """

    if not os.path.exists(path):
        return {
            "return_code": 1,
            "stdout": "",
            "stderr": "",
            "error": f"Path does not exist: {path}",
        }

    if os.path.isfile(path):

        filename = os.path.basename(path).lower()

        if filename.endswith(".jar"):
            app_type = "java-jar"

        elif filename.endswith(".war"):
            app_type = "java-war"

        else:
            app_type = "unknown"

        return {
            "return_code": 0,
            "stdout": f"Detected application type: {app_type}",
            "stderr": "",
            "command": ["application-detection", path],
        }

    files = os.listdir(path)

    lower_files = [
        item.lower()
        for item in files
    ]

    # --------------------------------------------------------
    # Java
    # --------------------------------------------------------

    if "pom.xml" in lower_files:
        app_type = "java-maven"

    elif "build.gradle" in lower_files:
        app_type = "java-gradle"

    elif "build.gradle.kts" in lower_files:
        app_type = "java-gradle"

    elif any(
        item.endswith(".jar")
        for item in lower_files
    ):
        app_type = "java-jar"

    # --------------------------------------------------------
    # Python
    # --------------------------------------------------------

    elif "requirements.txt" in lower_files:
        app_type = "python"

    elif "pyproject.toml" in lower_files:
        app_type = "python"

    elif "setup.py" in lower_files:
        app_type = "python"

    # --------------------------------------------------------
    # Node.js
    # --------------------------------------------------------

    elif "package.json" in lower_files:
        app_type = "nodejs"

    # --------------------------------------------------------
    # Go
    # --------------------------------------------------------

    elif "go.mod" in lower_files:
        app_type = "golang"

    # --------------------------------------------------------
    # .NET
    # --------------------------------------------------------

    elif any(
        item.endswith(".csproj")
        for item in lower_files
    ):
        app_type = "dotnet"

    elif any(
        item.endswith(".fsproj")
        for item in lower_files
    ):
        app_type = "dotnet"

    # --------------------------------------------------------
    # PHP
    # --------------------------------------------------------

    elif "composer.json" in lower_files:
        app_type = "php"

    # --------------------------------------------------------
    # Existing Dockerfile
    # --------------------------------------------------------

    elif "dockerfile" in lower_files:
        app_type = "dockerfile"

    else:
        app_type = "unknown"

    return {
        "return_code": 0,
        "stdout": f"Detected application type: {app_type}",
        "stderr": "",
        "command": [
            "application-detection",
            path,
        ],
    }


# ============================================================
# BASE IMAGE RECOMMENDATION
# ============================================================

def recommend_base_image(
    application_type,
    user_base_image=""
):
    """
    Select a base image.

    User-provided base image always takes priority.
    """

    if user_base_image:

        return {
            "return_code": 0,
            "stdout": (
                f"Using user-provided base image: "
                f"{user_base_image}"
            ),
            "stderr": "",
        }

    recommendations = {

        "java-jar":
            "eclipse-temurin:21-jre",

        "java-maven":
            "eclipse-temurin:21-jdk",

        "java-gradle":
            "eclipse-temurin:21-jdk",

        "java-war":
            "tomcat:10-jre21-temurin",

        "python":
            "python:3.12-slim",

        "nodejs":
            "node:22-slim",

        "golang":
            "golang:1.24",

        "dotnet":
            "mcr.microsoft.com/dotnet/aspnet:9.0",

        "php":
            "php:8.3-apache",

        "dockerfile":
            "USER_PROVIDED_DOCKERFILE",

        "unknown":
            "ubuntu:24.04",
    }

    image = recommendations.get(
        application_type,
        "ubuntu:24.04"
    )

    return {
        "return_code": 0,
        "stdout": (
            f"Recommended base image: {image}\n"
            f"Application type: {application_type}"
        ),
        "stderr": "",
    }


# ============================================================
# DOCKERFILE GENERATION
# ============================================================

def generate_dockerfile(
    application_type,
    source_path=".",
    base_image="",
    image_type="auto",
    app_port=8080,
    app_directory="/app",
    run_as_user="10001",
    environment_variables="",
    java_opts="",
    start_command=""
):
    """
    Generate a generic Dockerfile.

    image_type:
        auto
        normal
        multistage
    """

    # --------------------------------------------------------
    # Validate application type
    # --------------------------------------------------------

    if application_type == "unknown":

        return {
            "return_code": 1,
            "stdout": "",
            "stderr": "",
            "error": (
                "Unable to determine application type. "
                "Please provide the application type."
            ),
        }

    # --------------------------------------------------------
    # Automatic image strategy
    # --------------------------------------------------------

    if image_type == "auto":

        if application_type in [
            "java-maven",
            "java-gradle",
            "python",
            "nodejs",
            "golang",
            "dotnet",
        ]:

            selected_image_type = "multistage"

        else:

            selected_image_type = "normal"

    else:

        selected_image_type = image_type

    # --------------------------------------------------------
    # Default base image
    # --------------------------------------------------------

    if not base_image:

        base_result = recommend_base_image(
            application_type
        )

        base_image = base_result["stdout"].split(
            ": ",
            1
        )[-1].split("\n")[0]

    # --------------------------------------------------------
    # Environment variables
    # --------------------------------------------------------

    env_lines = ""

    if environment_variables:

        pairs = environment_variables.split(",")

        for pair in pairs:

            pair = pair.strip()

            if "=" not in pair:
                continue

            key, value = pair.split(
                "=",
                1
            )

            key = key.strip()
            value = value.strip()

            # Do not bake obvious secrets into image.
            if any(
                secret_word in key.lower()
                for secret_word in [
                    "password",
                    "secret",
                    "token",
                    "apikey",
                    "api_key",
                    "private_key",
                ]
            ):

                continue

            env_lines += (
                f"ENV {key}=\"{value}\"\n"
            )

    # ========================================================
    # JAVA
    # ========================================================

    if application_type == "java-jar":

        jar_file = None

        for item in os.listdir(source_path):

            if item.lower().endswith(".jar"):

                jar_file = item
                break

        if not jar_file:

            return {
                "return_code": 1,
                "stdout": "",
                "stderr": "",
                "error": (
                    "No JAR file found in "
                    f"{source_path}"
                ),
            }

        dockerfile = f"""# Generated Dockerfile
# Application: Java JAR

FROM {base_image}

WORKDIR {app_directory}

COPY {jar_file} app.jar

{env_lines}ENV JAVA_OPTS="{java_opts}"

EXPOSE {app_port}

USER {run_as_user}

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
"""

    # ========================================================
    # JAVA MAVEN
    # ========================================================

    elif application_type == "java-maven":

        dockerfile = f"""# Generated multi-stage Dockerfile
# Application: Java Maven

FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /build

COPY pom.xml .

COPY src ./src

RUN mvn clean package -DskipTests

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /build/target/*.jar app.jar

{env_lines}ENV JAVA_OPTS="{java_opts}"

EXPOSE {app_port}

USER {run_as_user}

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
"""

    # ========================================================
    # JAVA GRADLE
    # ========================================================

    elif application_type == "java-gradle":

        dockerfile = f"""# Generated multi-stage Dockerfile
# Application: Java Gradle

FROM gradle:8-jdk21 AS build

WORKDIR /build

COPY . .

RUN gradle clean build -x test

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /build/build/libs/*.jar app.jar

{env_lines}ENV JAVA_OPTS="{java_opts}"

EXPOSE {app_port}

USER {run_as_user}

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
"""

    # ========================================================
    # PYTHON
    # ========================================================

    elif application_type == "python":

        if start_command:

            command = start_command

        else:

            command = (
                "python app.py"
            )

        if selected_image_type == "multistage":

            dockerfile = f"""# Generated Dockerfile
# Application: Python

FROM python:3.12-slim AS build

WORKDIR /build

COPY requirements.txt .

RUN pip install --no-cache-dir \
    --prefix=/install \
    -r requirements.txt

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /install /usr/local

COPY . .

{env_lines}

EXPOSE {app_port}

USER {run_as_user}

CMD ["sh", "-c", "{command}"]
"""

        else:

            dockerfile = f"""# Generated Dockerfile
# Application: Python

FROM {base_image}

WORKDIR {app_directory}

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

{env_lines}

EXPOSE {app_port}

USER {run_as_user}

CMD ["sh", "-c", "{command}"]
"""

    # ========================================================
    # NODE
    # ========================================================

    elif application_type == "nodejs":

        command = (
            start_command
            if start_command
            else "npm start"
        )

        if selected_image_type == "multistage":

            dockerfile = f"""# Generated multi-stage Dockerfile
# Application: Node.js

FROM {base_image} AS build

WORKDIR /build

COPY package*.json ./

RUN npm ci

COPY . .

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /build ./

{env_lines}

EXPOSE {app_port}

USER {run_as_user}

CMD ["sh", "-c", "{command}"]
"""

        else:

            dockerfile = f"""# Generated Dockerfile
# Application: Node.js

FROM {base_image}

WORKDIR {app_directory}

COPY package*.json ./

RUN npm ci

COPY . .

{env_lines}

EXPOSE {app_port}

USER {run_as_user}

CMD ["sh", "-c", "{command}"]
"""

    # ========================================================
    # GO
    # ========================================================

    elif application_type == "golang":

        dockerfile = f"""# Generated multi-stage Dockerfile
# Application: Go

FROM golang:1.24 AS build

WORKDIR /build

COPY go.mod go.sum* ./

RUN go mod download

COPY . .

RUN go build -o application .

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /build/application application

EXPOSE {app_port}

USER {run_as_user}

ENTRYPOINT ["./application"]
"""

    # ========================================================
    # DOTNET
    # ========================================================

    elif application_type == "dotnet":

        dockerfile = f"""# Generated multi-stage Dockerfile
# Application: .NET

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

WORKDIR /src

COPY . .

RUN dotnet publish -c Release -o /app/publish

FROM {base_image}

WORKDIR {app_directory}

COPY --from=build /app/publish .

EXPOSE {app_port}

USER {run_as_user}

ENTRYPOINT ["dotnet", "app.dll"]
"""

    # ========================================================
    # PHP
    # ========================================================

    elif application_type == "php":

        dockerfile = f"""# Generated Dockerfile
# Application: PHP

FROM {base_image}

WORKDIR {app_directory}

COPY . .

{env_lines}

EXPOSE {app_port}

USER {run_as_user}
"""

    # ========================================================
    # CUSTOM / DOCKERFILE
    # ========================================================

    elif application_type == "dockerfile":

        return {
            "return_code": 0,
            "stdout": (
                "Existing Dockerfile detected.\n"
                "No new Dockerfile was generated."
            ),
            "stderr": "",
        }

    else:

        return {
            "return_code": 1,
            "stdout": "",
            "stderr": "",
            "error": (
                f"Dockerfile generation is not yet "
                f"implemented for: {application_type}"
            ),
        }

    # ========================================================
    # WRITE FILE
    # ========================================================

    os.makedirs(
        "generated",
        exist_ok=True
    )

    dockerfile_path = (
        "generated/Dockerfile"
    )

    with open(
        dockerfile_path,
        "w",
        encoding="utf-8"
    ) as file:

        file.write(
            dockerfile
        )

    return {
        "return_code": 0,
        "stdout": (
            f"Dockerfile generated successfully.\n\n"
            f"Application Type: {application_type}\n"
            f"Image Type: {selected_image_type}\n"
            f"Base Image: {base_image}\n"
            f"Port: {app_port}\n"
            f"Working Directory: {app_directory}\n\n"
            f"File: {dockerfile_path}\n\n"
            f"{dockerfile}"
        ),
        "stderr": "",
        "command": [
            "generate_dockerfile"
        ],
    }


# ============================================================
# DOCKER BUILD
# ============================================================

def docker_build(
    image_name,
    dockerfile_path="generated/Dockerfile",
    build_context="."
):
    """
    Build Docker image using Docker CLI.
    """

    return run_command([
        "docker",
        "build",
        "-f",
        dockerfile_path,
        "-t",
        image_name,
        build_context,
    ])


# ============================================================
# IMAGE INSPECTION
# ============================================================

def docker_image_inspect(image):

    return run_command([
        "docker",
        "image",
        "inspect",
        image,
    ])


# ============================================================
# IMAGE HISTORY
# ============================================================

def docker_image_history(image):

    return run_command([
        "docker",
        "history",
        image,
    ])


# ============================================================
# IMAGE SIZE
# ============================================================

def docker_image_size(image):

    return run_command([
        "docker",
        "image",
        "ls",
        image,
        "--format",
        "{{.Repository}}:{{.Tag}} {{.Size}}",
    ])


# ============================================================
# DOCKERFILE VALIDATION
# ============================================================

def validate_dockerfile(
    dockerfile_path="generated/Dockerfile"
):
    """
    Basic Dockerfile validation.

    Docker CLI is used where possible.
    """

    if not os.path.isfile(
        dockerfile_path
    ):

        return {
            "return_code": 1,
            "stdout": "",
            "stderr": "",
            "error": (
                f"Dockerfile not found: "
                f"{dockerfile_path}"
            ),
        }

    with open(
        dockerfile_path,
        "r",
        encoding="utf-8"
    ) as file:

        content = file.read()

    findings = []

    # --------------------------------------------------------
    # FROM
    # --------------------------------------------------------

    if not re.search(
        r"^\s*FROM\s+",
        content,
        re.MULTILINE | re.IGNORECASE
    ):

        findings.append(
            "ERROR: Dockerfile does not contain FROM."
        )

    # --------------------------------------------------------
    # USER
    # --------------------------------------------------------

    if not re.search(
        r"^\s*USER\s+",
        content,
        re.MULTILINE | re.IGNORECASE
    ):

        findings.append(
            "WARNING: Dockerfile does not define USER. "
            "Container may run as root."
        )

    # --------------------------------------------------------
    # EXPOSE
    # --------------------------------------------------------

    if not re.search(
        r"^\s*EXPOSE\s+",
        content,
        re.MULTILINE | re.IGNORECASE
    ):

        findings.append(
            "INFO: No EXPOSE instruction found."
        )

    # --------------------------------------------------------
    # ADD
    # --------------------------------------------------------

    if re.search(
        r"^\s*ADD\s+",
        content,
        re.MULTILINE | re.IGNORECASE
    ):

        findings.append(
            "INFO: ADD detected. Consider COPY "
            "when archive extraction is not required."
        )

    # --------------------------------------------------------
    # Secrets
    # --------------------------------------------------------

    if re.search(
        r"(password|secret|token|api[_-]?key)\s*=",
        content,
        re.IGNORECASE
    ):

        findings.append(
            "WARNING: Possible secret detected "
            "in Dockerfile."
        )

    # --------------------------------------------------------
    # Result
    # --------------------------------------------------------

    if not findings:

        findings.append(
            "No basic Dockerfile issues detected."
        )

    return {
        "return_code": 0,
        "stdout": "\n".join(findings),
        "stderr": "",
        "command": [
            "validate_dockerfile",
            dockerfile_path,
        ],
    }
