import json


def success_response(
    resource: str,
    columns: list,
    data: list
):
    return {
        "status": "success",
        "resource": resource,
        "columns": columns,
        "data": data
    }


def error_response(message: str):
    return {
        "status": "error",
        "message": message
    }


def text_response(
    resource: str,
    output: str
):
    return {
        "status": "success",
        "resource": resource,
        "output": output
    }


def to_json_string(data):
    return json.dumps(
        data,
        indent=2,
        default=str
    )
