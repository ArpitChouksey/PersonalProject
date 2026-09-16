# PersonalProject

Personal DevOps / Cloud Engineering projects — self-directed, hands-on builds covering Infrastructure as Code, container orchestration, cloud networking, observability, and Agentic AI tooling for infrastructure automation.

Each project lives on its own branch (see table below). Switch branches to view the code, IaC, and any project-specific README.

## 🗂 Projects

| Branch | Project | Description | Key Tech |
|---|---|---|---|
| [`P1-AWS-3TIER-APPLICATION`](../../tree/P1-AWS-3TIER-APPLICATION) | AWS Three-Tier Architecture | Classic three-tier app infrastructure — VPC, ALB, Auto Scaling Group — provisioned with Terraform, including import of brownfield resources. | Terraform, AWS VPC, ALB, ASG |
| [`P2-MS-EKS-APPLICATION`](../../tree/P2-MS-EKS-APPLICATION) | EKS Microservices Deployment | Multi-service application deployed on Amazon EKS, with infrastructure provisioned via Terraform and application delivery via ArgoCD GitOps. | AWS EKS, Kubernetes, Terraform, ArgoCD, Helm |
| [`P3-MultiEnv-Terrafrom-Infra`](../../tree/P3-MultiEnv-Terrafrom-Infra) | Multi-Account AWS Landing Zone & Network Automation | Production-style multi-account AWS environment (management/dev/prod) using AWS Organizations, cross-account IAM roles, and modular Terraform with S3 + DynamoDB remote state. | Terraform, AWS Organizations, IAM, VPC, WAF, API Gateway |
| [`P4-S3-CloudFront-Serverless`](../../tree/P4-S3-CloudFront-Serverless) | S3 + CloudFront Serverless Hosting | Serverless static hosting pattern using S3 as the origin and CloudFront for global CDN delivery. | AWS S3, CloudFront, Terraform |
| [`P5-SRE-Monitoring`](../../tree/P5-SRE-Monitoring) | SRE Monitoring Stack | Observability setup for metrics, dashboards, and alerting on cloud infrastructure and workloads. | Prometheus, Grafana |
| [`P6-VPNClientSetup`](../../tree/P6-VPNClientSetup) | AWS Client VPN Setup | Secure private access to internal EC2 workloads via AWS Client VPN with a full PKI chain (root CA, server/client certificates). | AWS Client VPN, PKI, ACM |
| [`P7-CloudFormation`](../../tree/P7-CloudFormation) | CloudFormation Infrastructure | Infrastructure-as-code templates using AWS CloudFormation. | AWS CloudFormation |
| [`P8-TerraformCode`](../../tree/P8-TerraformCode) | Terraform Code Library | Reusable Terraform modules and reference configurations. | Terraform |
| [`P9-MCP-CUSTOM-SERVER`](../../tree/P9-MCP-CUSTOM-SERVER) | Custom MCP Server | A Model Context Protocol (MCP) server exposing infrastructure operations (Kubernetes, Terraform) as callable tools for LLM-based agents. | Python, FastAPI, MCP |
| [`P10-AgenticAi`](../../tree/P10-AgenticAi) | AI-Powered Infrastructure Agent Suite | Three LLM-driven infrastructure agents (Kubernetes, Terraform, Docker) enabling natural-language execution and troubleshooting instead of raw CLI syntax. | React, FastAPI, Ollama, Kubernetes, Terraform, Docker |

## 🧰 Stack Overview

- **Cloud:** AWS, Azure (multi-cloud exposure)
- **IaC:** Terraform, AWS CloudFormation
- **Containers & Orchestration:** Docker, Kubernetes (EKS), Helm, ArgoCD
- **Networking & Security:** AWS Client VPN, PKI, WAF, IAM
- **Observability:** Prometheus, Grafana
- **AI / Agentic Engineering:** MCP servers, LLM tool-orchestration (Ollama), FastAPI

---
*Maintained by [Arpit Kumar Chouksey](https://www.linkedin.com/in/arpit-kumar-chouksey) — Senior DevOps / Site Reliability Engineer.*
