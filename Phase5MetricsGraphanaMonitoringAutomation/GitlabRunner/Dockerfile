# ==========================================
# Stage 1 - Build Tools
# ==========================================
FROM python:3.12-slim AS builder

ARG KUBECTL_VERSION=v1.34.1
ARG HELM_VERSION=v3.19.0
ARG TERRAFORM_VERSION=1.13.0

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip install --no-cache-dir ansible

# Install kubectl
RUN curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl

# Install Helm
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    -o helm.tar.gz && \
    tar -xzf helm.tar.gz

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install yq
RUN wget -O yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x yq

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o awscliv2.zip && \
    unzip awscliv2.zip

# ==========================================
# Stage 2 - Runtime
# ==========================================
FROM python:3.12-slim

LABEL maintainer="Arpit Chouksey"
LABEL project="SRE Automation Platform"

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Ansible
COPY --from=builder /usr/local/bin/ansible* /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12

# Copy kubectl
COPY --from=builder /kubectl /usr/local/bin/kubectl

# Copy Helm
COPY --from=builder /linux-amd64/helm /usr/local/bin/helm

# Copy Terraform
COPY --from=builder /terraform /usr/local/bin/terraform

# Copy yq
COPY --from=builder /yq /usr/local/bin/yq

# Install AWS CLI
COPY --from=builder /aws /tmp/aws

RUN /tmp/aws/install && \
    rm -rf /tmp/aws

WORKDIR /workspace

CMD ["bash"]
