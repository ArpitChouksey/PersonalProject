#!/bin/bash

set -e

echo "======================================"
echo " Kubernetes Agent Tool Restructuring"
echo "======================================"

TOOLS="app/tools"

# --------------------------------------
# Create directory structure
# --------------------------------------

directories=(
    "$TOOLS/cluster"

    "$TOOLS/namespace"

    "$TOOLS/pods"

    "$TOOLS/deployments"

    "$TOOLS/services"

    "$TOOLS/workloads"

    "$TOOLS/configuration/configmap"
    "$TOOLS/configuration/secret"

    "$TOOLS/rbac/role"
    "$TOOLS/rbac/rolebinding"
    "$TOOLS/rbac/clusterrole"
    "$TOOLS/rbac/clusterrolebinding"

    "$TOOLS/scheduling/node_selector"
    "$TOOLS/scheduling/node_affinity"
    "$TOOLS/scheduling/pod_affinity"
    "$TOOLS/scheduling/pod_anti_affinity"
    "$TOOLS/scheduling/taints"
    "$TOOLS/scheduling/tolerations"

    "$TOOLS/resources"

    "$TOOLS/autoscaling/hpa"

    "$TOOLS/manifests"

    "$TOOLS/troubleshooting"

    "$TOOLS/remediation"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done

echo "Directory structure created."

# --------------------------------------
# Create Python package files
# --------------------------------------

find "$TOOLS" -type d -exec touch {}/__init__.py \;

echo "__init__.py files created."

# --------------------------------------
# Move existing tools
# --------------------------------------

move_if_exists() {
    FILE="$1"
    DEST="$2"

    if [ -f "$TOOLS/$FILE" ]; then
        mv "$TOOLS/$FILE" "$DEST/"
        echo "Moved: $FILE -> $DEST"
    fi
}

# --------------------------------------
# Cluster
# --------------------------------------

move_if_exists "get_nodes.py" "$TOOLS/cluster"

move_if_exists "get_cluster_info.py" "$TOOLS/cluster"

move_if_exists "get_cluster_version.py" "$TOOLS/cluster"

# --------------------------------------
# Namespace
# --------------------------------------

move_if_exists "list_namespaces.py" "$TOOLS/namespace"

move_if_exists "create_namespace.py" "$TOOLS/namespace"

move_if_exists "delete_namespace.py" "$TOOLS/namespace"

# --------------------------------------
# Pods
# --------------------------------------

move_if_exists "get_pods.py" "$TOOLS/pods"

move_if_exists "get_all_pods.py" "$TOOLS/pods"

move_if_exists "describe_pod.py" "$TOOLS/pods"

move_if_exists "get_pod_logs.py" "$TOOLS/pods"

move_if_exists "stream_pod_logs.py" "$TOOLS/pods"

move_if_exists "execute_in_pod.py" "$TOOLS/pods"

move_if_exists "delete_pod.py" "$TOOLS/pods"

# --------------------------------------
# Deployments
# --------------------------------------

move_if_exists "get_deployments.py" "$TOOLS/deployments"

move_if_exists "create_deployment.py" "$TOOLS/deployments"

move_if_exists "apply_deployment.py" "$TOOLS/deployments"

move_if_exists "scale_deployment.py" "$TOOLS/deployments"

move_if_exists "rollout_status.py" "$TOOLS/deployments"

move_if_exists "rollout_undo.py" "$TOOLS/deployments"

move_if_exists "rollout_restart.py" "$TOOLS/deployments"

# --------------------------------------
# Services
# --------------------------------------

move_if_exists "get_services.py" "$TOOLS/services"

move_if_exists "describe_service.py" "$TOOLS/services"

move_if_exists "get_endpoints.py" "$TOOLS/services"

move_if_exists "port_forward.py" "$TOOLS/services"

# --------------------------------------
# Workloads
# --------------------------------------

move_if_exists "replicaset.py" "$TOOLS/workloads"

move_if_exists "statefulset.py" "$TOOLS/workloads"

move_if_exists "daemonset.py" "$TOOLS/workloads"

# --------------------------------------
# Configuration
# --------------------------------------

move_if_exists "configmap.py" "$TOOLS/configuration/configmap"

move_if_exists "secret.py" "$TOOLS/configuration/secret"

# --------------------------------------
# RBAC
# --------------------------------------

move_if_exists "role.py" "$TOOLS/rbac/role"

move_if_exists "rolebinding.py" "$TOOLS/rbac/rolebinding"

move_if_exists "clusterrole.py" "$TOOLS/rbac/clusterrole"

move_if_exists "clusterrolebinding.py" "$TOOLS/rbac/clusterrolebinding"

move_if_exists "auth_can_i.py" "$TOOLS/rbac"

# --------------------------------------
# Scheduling
# --------------------------------------

move_if_exists "node_selector.py" "$TOOLS/scheduling/node_selector"

move_if_exists "node_affinity.py" "$TOOLS/scheduling/node_affinity"

move_if_exists "pod_affinity.py" "$TOOLS/scheduling/pod_affinity"

move_if_exists "pod_anti_affinity.py" "$TOOLS/scheduling/pod_anti_affinity"

move_if_exists "taints.py" "$TOOLS/scheduling/taints"

move_if_exists "tolerations.py" "$TOOLS/scheduling/tolerations"

# --------------------------------------
# Resources
# --------------------------------------

move_if_exists "resource_requests.py" "$TOOLS/resources"

move_if_exists "resource_limits.py" "$TOOLS/resources"

move_if_exists "resource_quota.py" "$TOOLS/resources"

move_if_exists "limit_range.py" "$TOOLS/resources"

# --------------------------------------
# Autoscaling
# --------------------------------------

move_if_exists "hpa.py" "$TOOLS/autoscaling/hpa"

# --------------------------------------
# Manifests
# --------------------------------------

move_if_exists "apply_manifest.py" "$TOOLS/manifests"

move_if_exists "delete_manifest.py" "$TOOLS/manifests"

move_if_exists "get_resource_yaml.py" "$TOOLS/manifests"

move_if_exists "validate_manifest.py" "$TOOLS/manifests"

# --------------------------------------
# Troubleshooting
# --------------------------------------

move_if_exists "events.py" "$TOOLS/troubleshooting"

move_if_exists "failed_pods.py" "$TOOLS/troubleshooting"

move_if_exists "pending_pods.py" "$TOOLS/troubleshooting"

move_if_exists "crashloop_pods.py" "$TOOLS/troubleshooting"

move_if_exists "diagnose_pod.py" "$TOOLS/troubleshooting"

# --------------------------------------
# Remediation
# --------------------------------------

move_if_exists "restart_pod.py" "$TOOLS/remediation"

move_if_exists "restart_deployment.py" "$TOOLS/remediation"

move_if_exists "scale_deployment.py" "$TOOLS/remediation"

move_if_exists "rollback_deployment.py" "$TOOLS/remediation"

move_if_exists "verify_result.py" "$TOOLS/remediation"

echo ""
echo "======================================"
echo " Restructuring completed"
echo "======================================"
