from app.agent.tool_loader import load_tools


tools = load_tools()

print("\nDiscovered Kubernetes Tools:\n")

for tool in tools:
    print(f"- {tool.__name__}")
