import { useState } from "react";
import "./App.css";

const API_URL = "http://127.0.0.1:8000";

function App() {
  const [workspacePath, setWorkspacePath] = useState("");
  const [connectedPath, setConnectedPath] = useState("");
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [connected, setConnected] = useState(false);

  // =========================================================
  // API
  // =========================================================

  const sendToAgent = async (text) => {
    const response = await fetch(`${API_URL}/agent/chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: text,
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.detail || "Request failed");
    }

    return data;
  };

  // =========================================================
  // Add message
  // =========================================================

  const addMessage = (sender, content) => {
    setMessages((prev) => [
      ...prev,
      {
        id: Date.now() + Math.random(),
        sender,
        content,
      },
    ]);
  };

  // =========================================================
  // Connect workspace
  // =========================================================

  const connectWorkspace = async () => {
    const path = workspacePath.trim();

    if (!path) {
      addMessage("system", {
        type: "error",
        message: "Please enter a Terraform workspace path.",
      });
      return;
    }

    setLoading(true);

    try {
      const data = await sendToAgent(`terraform path:${path}`);

      if (data.status === "success") {
        setConnected(true);

        const savedPath = data.terraform_path || path;

        setConnectedPath(savedPath);

        addMessage("system", {
          type: "workspace",
          path: savedPath,
        });
      } else {
        setConnected(false);

        addMessage("system", {
          type: "error",
          message: data.message || "Unable to connect workspace.",
        });
      }
    } catch (error) {
      setConnected(false);

      addMessage("system", {
        type: "error",
        message:
          error.message || "Failed to connect to backend.",
      });
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // Send chat
  // =========================================================

  const sendMessage = async () => {
    const text = message.trim();

    if (!text || loading) {
      return;
    }

    if (!connected) {
      addMessage("system", {
        type: "error",
        message: "Please connect a Terraform workspace first.",
      });
      return;
    }

    addMessage("user", text);
    setMessage("");
    setLoading(true);

    try {
      const data = await sendToAgent(text);
      addMessage("agent", data);
    } catch (error) {
      addMessage("system", {
        type: "error",
        message:
          error.message ||
          "Failed to communicate with Terraform Agent.",
      });
    } finally {
      setLoading(false);
    }
  };

  // =========================================================
  // Keyboard
  // =========================================================

  const handleKeyDown = (event) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  };

  // =========================================================
  // Clean Terraform ANSI output
  // =========================================================

  const cleanTerraformOutput = (text) => {
    if (!text) {
      return "";
    }

    return String(text)
      .replace(/\u001b\[[0-9;]*m/g, "")
      .replace(/\u001b\[[0-9;]*[A-Za-z]/g, "");
  };

  // =========================================================
  // Format action
  // =========================================================

  const formatAction = (action) => {
    if (!action) {
      return "-";
    }

    if (Array.isArray(action)) {
      action = action.join(", ");
    }

    const value = String(action).toUpperCase();

    if (
      value.includes("CREATE") ||
      value.includes("NEW") ||
      value.includes("ADD")
    ) {
      return "CREATE";
    }

    if (
      value.includes("UPDATE") ||
      value.includes("MODIFY")
    ) {
      return "UPDATE";
    }

    if (value.includes("REPLACE") || value.includes("RECREATE")) {
      return "REPLACE";
    }

    if (
      value.includes("DESTROY") ||
      value.includes("DELETE") ||
      value.includes("REMOVE")
    ) {
      return "DESTROY";
    }

    return value;
  };

  // =========================================================
  // Action class
  // =========================================================

  const getActionClass = (action) => {
    switch (formatAction(action)) {
      case "CREATE":
        return "action-create";

      case "UPDATE":
        return "action-update";

      case "REPLACE":
        return "action-replace";

      case "DESTROY":
        return "action-destroy";

      default:
        return "";
    }
  };

  // =========================================================
  // Summary
  // =========================================================

  const renderSummary = (summary) => {
    if (!summary || typeof summary !== "object") {
      return null;
    }

    const newCount =
      summary.new ??
      summary.create ??
      summary.created ??
      0;

    const modifiedCount =
      summary.modified ??
      summary.update ??
      summary.updated ??
      0;

    const replacedCount =
      summary.replaced ??
      summary.replace ??
      0;

    const destroyedCount =
      summary.destroyed ??
      summary.destroy ??
      summary.deleted ??
      0;

    const total =
      summary.total_changes ??
      summary.total ??
      newCount +
        modifiedCount +
        replacedCount +
        destroyedCount;

    return (
      <div className="summary-grid">
        <div className="summary-item create">
          <span className="summary-number">
            {newCount}
          </span>

          <span className="summary-label">
            CREATE
          </span>
        </div>

        <div className="summary-item update">
          <span className="summary-number">
            {modifiedCount}
          </span>

          <span className="summary-label">
            MODIFY
          </span>
        </div>

        <div className="summary-item replace">
          <span className="summary-number">
            {replacedCount}
          </span>

          <span className="summary-label">
            REPLACE
          </span>
        </div>

        <div className="summary-item destroy">
          <span className="summary-number">
            {destroyedCount}
          </span>

          <span className="summary-label">
            DESTROY
          </span>
        </div>

        <div className="summary-item total">
          <span className="summary-number">
            {total}
          </span>

          <span className="summary-label">
            TOTAL
          </span>
        </div>
      </div>
    );
  };

  // =========================================================
  // Normalize resource object
  // =========================================================

  const normalizeResource = (resource, fallbackAction = null) => {
    if (!resource) {
      return null;
    }

    if (typeof resource === "string") {
      return {
        address: resource,
        type: "-",
        action: fallbackAction || "CREATE",
        description: "",
      };
    }

    const change = resource.change || {};

    let action =
      resource.action ??
      resource.actions ??
      change.action ??
      change.actions ??
      fallbackAction ??
      "";

    if (Array.isArray(action)) {
      action = action.join(", ");
    }

    const address =
      resource.address ??
      resource.resource ??
      resource.name ??
      resource.resource_address ??
      resource.full_address ??
      "-";

    const type =
      resource.type ??
      resource.resource_type ??
      resource.kind ??
      "-";

    const description =
      resource.description ??
      resource.message ??
      resource.reason ??
      "";

    return {
      address,
      type,
      action,
      description,
    };
  };

  // =========================================================
  // Recursively find Terraform resources
  // =========================================================

  const extractResources = (value, found = [], visited = new Set()) => {
    if (value === null || value === undefined) {
      return found;
    }

    if (typeof value !== "object") {
      return found;
    }

    if (visited.has(value)) {
      return found;
    }

    visited.add(value);

    // -------------------------------------------------------
    // Array
    // -------------------------------------------------------

    if (Array.isArray(value)) {
      value.forEach((item) => {
        if (item && typeof item === "object") {
          const normalized = normalizeResource(item);

          if (
            normalized &&
            normalized.address &&
            normalized.address !== "-"
          ) {
            const hasTerraformAddress =
              String(normalized.address).includes(".") ||
              String(normalized.address).includes("[") ||
              String(normalized.address).includes("_");

            if (hasTerraformAddress) {
              found.push(normalized);
            }
          }

          extractResources(item, found, visited);
        }
      });

      return found;
    }

    // -------------------------------------------------------
    // Direct resource object
    // -------------------------------------------------------

    const looksLikeResource =
      value.address ||
      value.resource ||
      value.resource_address ||
      value.full_address;

    if (looksLikeResource) {
      const normalized = normalizeResource(value);

      if (normalized) {
        found.push(normalized);
      }
    }

    // -------------------------------------------------------
    // Common Terraform keys
    // -------------------------------------------------------

    const resourceKeys = [
      "planned_changes",
      "resources",
      "changes",
      "resource_changes",
      "created",
      "creates",
      "to_create",
      "new_resources",
      "modified",
      "updated",
      "updates",
      "replaced",
      "replace",
      "destroyed",
      "destroy",
      "deleted",
      "missing_resources",
      "tables",
    ];

    resourceKeys.forEach((key) => {
      if (value[key] !== undefined) {
        const actionFallback =
          key.includes("create") ||
          key === "created" ||
          key === "creates" ||
          key === "new_resources"
            ? "CREATE"
            : key.includes("modify") ||
              key.includes("update") ||
              key === "modified" ||
              key === "updated"
            ? "UPDATE"
            : key.includes("replace")
            ? "REPLACE"
            : key.includes("destroy") ||
              key.includes("delete")
            ? "DESTROY"
            : null;

        if (Array.isArray(value[key])) {
          value[key].forEach((item) => {
            const normalized = normalizeResource(
              item,
              actionFallback
            );

            if (
              normalized &&
              normalized.address &&
              normalized.address !== "-"
            ) {
              found.push(normalized);
            }

            extractResources(item, found, visited);
          });
        } else {
          extractResources(
            value[key],
            found,
            visited
          );
        }
      }
    });

    // -------------------------------------------------------
    // Generic nested objects
    // -------------------------------------------------------

    Object.entries(value).forEach(([key, nested]) => {
      if (
        resourceKeys.includes(key) ||
        key === "summary" ||
        key === "stdout" ||
        key === "stderr"
      ) {
        return;
      }

      if (
        nested &&
        typeof nested === "object"
      ) {
        extractResources(
          nested,
          found,
          visited
        );
      }
    });

    return found;
  };

  // =========================================================
  // Remove duplicate resources
  // =========================================================

  const getUniqueResources = (resources) => {
    const map = new Map();

    resources.forEach((resource) => {
      if (!resource || !resource.address) {
        return;
      }

      const key =
        `${resource.address}|${resource.action}|${resource.type}`;

      if (!map.has(key)) {
        map.set(key, resource);
      }
    });

    return Array.from(map.values());
  };

  // =========================================================
  // Resources
  // =========================================================

  const renderResources = (result) => {
    if (!result) {
      return null;
    }

    const extracted = extractResources(result);

    const resources = getUniqueResources(extracted);

    if (resources.length === 0) {
      return null;
    }

    return (
      <div className="result-section">

        <div className="section-title">
          Terraform Resources
        </div>

        <div className="resource-count">
          {resources.length} resource
          {resources.length !== 1 ? "s" : ""} detected
        </div>

        <div className="terminal-table">

          <div className="terminal-table-header">
            <span>RESOURCE</span>
            <span>TYPE</span>
            <span>ACTION</span>
          </div>

          {resources.map((resource, index) => (
            <div
              className="terminal-table-row"
              key={`${resource.address}-${index}`}
            >

              <span className="resource-name">
                {resource.address}
              </span>

              <span>
                {resource.type}
              </span>

              <span>
                <span
                  className={`action-badge ${getActionClass(
                    resource.action
                  )}`}
                >
                  {formatAction(
                    resource.action
                  )}
                </span>
              </span>

            </div>
          ))}

        </div>
      </div>
    );
  };

  // =========================================================
  // Drift
  // =========================================================

  const renderDrift = (result) => {
    if (!result?.summary) {
      return null;
    }

    const summary = result.summary;

    const hasDriftData =
      summary.drift_detected !== undefined ||
      summary.drifted_resources !== undefined ||
      summary.missing_resources !== undefined ||
      summary.extra_resources !== undefined;

    if (!hasDriftData) {
      return null;
    }

    return (
      <div className="result-section">

        <div className="section-title">
          Terraform Drift
        </div>

        <div className="drift-table">

          <div className="drift-row">
            <span>Drift Detected</span>

            <strong
              className={
                summary.drift_detected
                  ? "drift-yes"
                  : "drift-no"
              }
            >
              {summary.drift_detected
                ? "YES"
                : "NO"}
            </strong>
          </div>

          <div className="drift-row">
            <span>Drifted Resources</span>

            <strong>
              {summary.drifted_resources ?? 0}
            </strong>
          </div>

          <div className="drift-row">
            <span>Missing Resources</span>

            <strong>
              {summary.missing_resources ?? 0}
            </strong>
          </div>

          <div className="drift-row">
            <span>Extra Resources</span>

            <strong>
              {summary.extra_resources ?? 0}
            </strong>
          </div>

          <div className="drift-row">
            <span>Planned Updates</span>

            <strong>
              {summary.planned_updates ?? 0}
            </strong>
          </div>

        </div>
      </div>
    );
  };

  // =========================================================
  // Missing resources
  // =========================================================

  const renderMissingResources = (result) => {
    if (
      !result ||
      !Array.isArray(result.missing_resources) ||
      result.missing_resources.length === 0
    ) {
      return null;
    }

    return (
      <div className="result-section">

        <div className="section-title">
          Missing Resources
        </div>

        <div className="terminal-table">

          <div className="terminal-table-header">
            <span>RESOURCE</span>
            <span>TYPE</span>
            <span>ACTION</span>
            <span>DESCRIPTION</span>
          </div>

          {result.missing_resources.map(
            (resource, index) => (
              <div
                className="terminal-table-row missing-row"
                key={index}
              >

                <span className="resource-name">
                  {resource.resource ||
                    resource.address ||
                    "-"}
                </span>

                <span>
                  {resource.type || "-"}
                </span>

                <span>
                  <span className="action-badge action-create">
                    {resource.action ||
                      "CREATE"}
                  </span>
                </span>

                <span>
                  {resource.message ||
                    resource.description ||
                    "-"}
                </span>

              </div>
            )
          )}

        </div>
      </div>
    );
  };

  // =========================================================
  // Terraform result
  // =========================================================

  const renderTerraformResult = (data) => {
    if (!data || typeof data !== "object") {
      return (
        <div className="terminal-output">
          {String(data)}
        </div>
      );
    }

    if (data.status === "error") {
      return (
        <div className="terminal-error">

          <div className="terminal-error-title">
            TERRAFORM ERROR
          </div>

          <pre>
            {data.message ||
              data.result?.message ||
              "Terraform operation failed."}
          </pre>

        </div>
      );
    }

    const result = data.result || data;

    return (
      <div className="terraform-result">

        {/* Command */}

        {data.tool && (
          <div className="terminal-command">
            <span>$</span> {data.tool}
          </div>
        )}

        {/* Workspace */}

        {data.terraform_path && (
          <div className="terminal-workspace">

            <span>
              WORKSPACE:
            </span>

            <code>
              {data.terraform_path}
            </code>

          </div>
        )}

        {/* Summary */}

        {result.summary &&
          !(
            result.summary.drift_detected !==
            undefined
          ) &&
          renderSummary(result.summary)}

        {/* Resources */}

        {renderResources(result)}

        {/* Drift */}

        {renderDrift(result)}

        {/* Missing resources */}

        {renderMissingResources(result)}

        {/* Terraform stdout */}

        {result.stdout && (
          <details
            className="raw-terminal"
            open
          >
            <summary>
              Terraform Terminal Output
            </summary>

            <pre>
              {cleanTerraformOutput(
                result.stdout
              )}
            </pre>
          </details>
        )}

        {/* Terraform stderr */}

        {result.stderr && (
          <details
            className="raw-terminal error-terminal"
          >
            <summary>
              Terraform Error Output
            </summary>

            <pre>
              {cleanTerraformOutput(
                result.stderr
              )}
            </pre>
          </details>
        )}

      </div>
    );
  };

  // =========================================================
  // Render message
  // =========================================================

  const renderMessage = (item) => {
    if (item.sender === "user") {
      return (
        <div
          className="chat-message user-message"
          key={item.id}
        >
          <div className="message-header">
            You
          </div>

          <div className="user-text">
            {item.content}
          </div>
        </div>
      );
    }

    if (item.sender === "system") {
      if (
        item.content?.type === "workspace"
      ) {
        return (
          <div
            className="chat-message system-message"
            key={item.id}
          >

            <div className="message-header">
              System
            </div>

            <div className="workspace-success">

              <strong>
                ✓ Workspace Connected
              </strong>

              <code>
                {item.content.path}
              </code>

            </div>

          </div>
        );
      }

      return (
        <div
          className="chat-message system-message"
          key={item.id}
        >

          <div className="message-header">
            System
          </div>

          <div className="system-error">
            {item.content?.message ||
              String(item.content)}
          </div>

        </div>
      );
    }

    return (
      <div
        className="chat-message agent-message"
        key={item.id}
      >

        <div className="message-header">
          Terraform Agent
        </div>

        {renderTerraformResult(
          item.content
        )}

      </div>
    );
  };

  // =========================================================
  // UI
  // =========================================================

  return (
    <div className="app">

      {/* HEADER */}

      <header className="header">

        <div>
          <h1>
            Terraform Agent
          </h1>

          <p>
            Agentic Infrastructure Assistant
          </p>
        </div>

        <div
          className={`connection-status ${
            connected
              ? "connected"
              : "not-connected"
          }`}
        >
          <span className="status-dot"></span>

          {connected
            ? "Connected"
            : "Not Connected"}
        </div>

      </header>

      <main className="main">

        {/* WORKSPACE */}

        <section className="workspace-card">

          <div className="card-title">
            Terraform Workspace
          </div>

          <div className="workspace-form">

            <input
              type="text"
              value={workspacePath}
              onChange={(e) =>
                setWorkspacePath(
                  e.target.value
                )
              }
              placeholder="Enter Terraform workspace path..."
              disabled={loading}
            />

            <button
              onClick={connectWorkspace}
              disabled={loading}
            >
              {loading
                ? "Connecting..."
                : "Connect Workspace"}
            </button>

          </div>

          {connectedPath && (
            <div className="connected-path">

              <span>
                Connected workspace
              </span>

              <code>
                {connectedPath}
              </code>

            </div>
          )}

        </section>

        {/* CHAT */}

        <section className="chat-card">

          <div className="chat-title">
            Terraform Chat
          </div>

          <div className="chat-container">

            {messages.length === 0 && (
              <div className="empty-chat">

                <div className="empty-icon">
                  $
                </div>

                <h3>
                  Terraform Agent
                </h3>

                <p>
                  Connect a workspace and ask
                  Terraform questions.
                </p>

                <div className="example-commands">

                  <button
                    onClick={() =>
                      setMessage(
                        "terraform init"
                      )
                    }
                  >
                    terraform init
                  </button>

                  <button
                    onClick={() =>
                      setMessage(
                        "terraform plan"
                      )
                    }
                  >
                    terraform plan
                  </button>

                  <button
                    onClick={() =>
                      setMessage(
                        "check terraform drift"
                      )
                    }
                  >
                    Check Drift
                  </button>

                  <button
                    onClick={() =>
                      setMessage(
                        "explain terraform plan"
                      )
                    }
                  >
                    Explain Plan
                  </button>

                </div>

              </div>
            )}

            {messages.map(renderMessage)}

            {loading && (
              <div className="loading-message">

                <span className="loading-dot"></span>

                Terraform Agent is working...

              </div>
            )}

          </div>

          {/* INPUT */}

          <div className="chat-input-container">

            <textarea
              value={message}
              onChange={(e) =>
                setMessage(e.target.value)
              }
              onKeyDown={handleKeyDown}
              placeholder={
                connected
                  ? "Ask Terraform Agent..."
                  : "Connect a workspace first..."
              }
              disabled={
                !connected || loading
              }
              rows={2}
            />

            <button
              onClick={sendMessage}
              disabled={
                !connected ||
                !message.trim() ||
                loading
              }
            >
              {loading
                ? "..."
                : "Send"}
            </button>

          </div>

        </section>

      </main>
    </div>
  );
}

export default App;
