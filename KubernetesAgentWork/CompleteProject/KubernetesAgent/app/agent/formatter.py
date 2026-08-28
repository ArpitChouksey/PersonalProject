def format_tool_result(
    tool_name,
    result
):

    if not isinstance(result, dict):

        return {
            "title": "Kubernetes Result",
            "table": [],
            "rows": [],
            "summary": str(result)
        }

    # ========================================================
    # ERROR
    # ========================================================

    if result.get("status") != "success":

        return result

    columns = result.get(
        "columns",
        []
    )

    data = result.get(
        "data",
        []
    )

    resource = result.get(
        "resource",
        tool_name
    )

    title = (
        f"Kubernetes {resource.title()}"
    )

    # ========================================================
    # EMPTY RESULT
    # ========================================================

    if not columns or not data:

        return {
            "title": title,
            "table": [],
            "rows": [],
            "summary": f"No {resource} found."
        }

    # ========================================================
    # SUMMARY
    # ========================================================

    summary = {
        "total": len(data)
    }

    # ========================================================
    # STATUS COUNTS
    # ========================================================

    if "STATUS" in columns:

        status_counts = {}

        for row in data:

            status = str(
                row.get(
                    "STATUS",
                    "Unknown"
                )
            )

            status_counts[status] = (
                status_counts.get(
                    status,
                    0
                ) + 1
            )

        summary["status"] = status_counts

    # ========================================================
    # RETURN
    # ========================================================

    return {
        "title": title,

        "table": columns,

        "rows": data,

        "summary": summary
    }
