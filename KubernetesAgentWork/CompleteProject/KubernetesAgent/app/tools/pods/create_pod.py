from kubernetes import client, config


def create_pod(
    name: str,
    image: str = "nginx",
    namespace: str = "default",
    replicas: int = 1
):
    """
    Create one or more Kubernetes Pods.
    """

    try:
        config.load_kube_config()

        v1 = client.CoreV1Api()

        created_pods = []

        for i in range(1, replicas + 1):

            pod_name = name if replicas == 1 else f"{name}-{i}"

            pod = client.V1Pod(
                metadata=client.V1ObjectMeta(
                    name=pod_name
                ),
                spec=client.V1PodSpec(
                    containers=[
                        client.V1Container(
                            name=pod_name,
                            image=image
                        )
                    ]
                )
            )

            result = v1.create_namespaced_pod(
                namespace=namespace,
                body=pod
            )

            created_pods.append(result.metadata.name)

        return {
            "status": "success",
            "resource": "pod",
            "name": name,
            "namespace": namespace,
            "image": image,
            "replicas": replicas,
            "pods": created_pods,
            "message": (
                f"Created {replicas} pod(s) successfully."
            )
        }

    except Exception as e:

        return {
            "status": "error",
            "resource": "pod",
            "name": name,
            "namespace": namespace,
            "message": str(e)
        }


# ============================================================
# AGENT TOOL METADATA
# ============================================================

create_pod.is_agent_tool = True
create_pod.tool_name = "create_pod"

create_pod.tool_description = """
Create one or more Kubernetes Pods.

Use this tool when the user wants to:

- create a pod
- create nginx pod
- create an nginx pod
- create multiple pods
- create pods with replicas
- run a pod
- start a pod
- launch a pod

Arguments:

- name:
    Base name of the Kubernetes pod.

- image:
    Container image to use.
    Default: nginx

- namespace:
    Kubernetes namespace.
    Default: default

- replicas:
    Number of pods to create.
    Default: 1
"""
