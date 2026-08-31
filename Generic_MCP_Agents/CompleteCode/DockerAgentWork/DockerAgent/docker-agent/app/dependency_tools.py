import json
import subprocess


def _run(command):

    try:

        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )

        return {
            "return_code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip()
        }

    except Exception as error:

        return {
            "return_code": 1,
            "stdout": "",
            "stderr": str(error)
        }


def container_dependency_graph():

    result = _run([
        "docker",
        "ps",
        "-a",
        "--format",
        "{{json .}}"
    ])

    if result["return_code"] != 0:
        return result

    containers = []

    for line in result["stdout"].splitlines():

        if not line.strip():
            continue

        try:
            containers.append(
                json.loads(line)
            )
        except json.JSONDecodeError:
            continue

    graph = []

    for container in containers:

        name = container.get(
            "Names",
            ""
        )

        inspect = _run([
            "docker",
            "inspect",
            name
        ])

        if inspect["return_code"] != 0:
            continue

        try:

            data = json.loads(
                inspect["stdout"]
            )[0]

            networks = data.get(
                "NetworkSettings",
                {}
            ).get(
                "Networks",
                {}
            )

            network_names = list(
                networks.keys()
            )

            graph.append({
                "container": name,
                "image": data.get(
                    "Config",
                    {}
                ).get(
                    "Image"
                ),
                "networks": network_names,
                "depends_on": data.get(
                    "Config",
                    {}
                ).get(
                    "Labels",
                    {}
                ).get(
                    "com.docker.compose.depends_on"
                )
            })

        except Exception:
            continue

    return {
        "return_code": 0,
        "containers": graph
    }


def network_container_map():

    result = _run([
        "docker",
        "network",
        "ls",
        "--format",
        "{{.Name}}"
    ])

    if result["return_code"] != 0:
        return result

    output = {}

    for network in result["stdout"].splitlines():

        network = network.strip()

        if not network:
            continue

        inspect = _run([
            "docker",
            "network",
            "inspect",
            network
        ])

        if inspect["return_code"] != 0:
            continue

        try:

            data = json.loads(
                inspect["stdout"]
            )[0]

            containers = data.get(
                "Containers",
                {}
            )

            output[network] = [
                {
                    "name": info.get(
                        "Name"
                    ),
                    "ipv4": info.get(
                        "IPv4Address"
                    ),
                    "mac": info.get(
                        "MacAddress"
                    )
                }
                for info in containers.values()
            ]

        except Exception:
            continue

    return {
        "return_code": 0,
        "networks": output
    }
