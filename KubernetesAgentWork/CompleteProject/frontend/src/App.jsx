import { useState } from "react";
import "./App.css";

const API_URL = "http://127.0.0.1:8000/agent/chat";

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  const sendMessage = async () => {
    const message = input.trim();

    if (!message || loading) {
      return;
    }

    // Add user message
    setMessages((prev) => [
      ...prev,
      {
        role: "user",
        type: "message",
        content: message,
      },
    ]);

    setInput("");
    setLoading(true);

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: message,
        }),
      });

      const data = await response.json();

      // -----------------------------------------
      // Normal LLM response
      // -----------------------------------------

      if (data.status === "success" && data.message) {
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            type: "message",
            content: data.message,
          },
        ]);

        return;
      }

      // -----------------------------------------
      // Kubernetes tool response
      // -----------------------------------------

      if (data.status === "success" && data.result) {
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            type: "tool",
            tool: data.tool,
            arguments: data.arguments || {},
            result: data.result,
          },
        ]);

        return;
      }

      // -----------------------------------------
      // Backend error
      // -----------------------------------------

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          type: "error",
          content:
            data.message || "Something went wrong while processing your request.",
        },
      ]);
    } catch (error) {
      console.error(error);

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          type: "error",
          content: "Unable to connect to Kubernetes Agent.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (event) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="app">

      {/* ---------------------------------- */}
      {/* HEADER */}
      {/* ---------------------------------- */}

      <header className="header">
        <div className="header-icon">
          ⚙
        </div>

        <div className="header-content">
          <div className="header-title">
            Kubernetes Agent
          </div>

          <div className="header-status">
            <span className="status-dot"></span>
            Online
          </div>
        </div>
      </header>

      {/* ---------------------------------- */}
      {/* CHAT */}
      {/* ---------------------------------- */}

      <main className="chat-container">

        {messages.length === 0 && (
          <div className="welcome">
            <div className="welcome-title">
              Kubernetes Agent
            </div>

            <div className="welcome-text">
              Ask me about your Kubernetes cluster.
            </div>
          </div>
        )}

        {messages.map((message, index) => (
          <ChatMessage
            key={index}
            message={message}
          />
        ))}

        {loading && (
          <div className="message-row assistant-row">

            <div className="avatar agent-avatar">
              ⚙
            </div>

            <div className="message-content">

              <div className="message-name">
                Kubernetes Agent
              </div>

              <div className="typing">
                <span></span>
                <span></span>
                <span></span>
              </div>

            </div>

          </div>
        )}

      </main>

      {/* ---------------------------------- */}
      {/* INPUT */}
      {/* ---------------------------------- */}

      <div className="input-area">

        <div className="input-box">

          <textarea
            value={input}
            onChange={(event) => setInput(event.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask Kubernetes Agent..."
            rows={1}
            disabled={loading}
          />

          <button
            className="send-button"
            onClick={sendMessage}
            disabled={!input.trim() || loading}
          >
            ➤
          </button>

        </div>

        <div className="input-hint">
          Press Enter to send
        </div>

      </div>

    </div>
  );
}


/* ========================================================= */
/* CHAT MESSAGE */
/* ========================================================= */

function ChatMessage({ message }) {

  /* ----------------------------------------- */
  /* USER */
  /* ----------------------------------------- */

  if (message.role === "user") {
    return (
      <div className="message-row user-row">

        <div className="avatar user-avatar">
          U
        </div>

        <div className="message-content">

          <div className="message-name">
            You
          </div>

          <div className="user-text">
            {message.content}
          </div>

        </div>

      </div>
    );
  }


  /* ----------------------------------------- */
  /* NORMAL LLM MESSAGE */
  /* ----------------------------------------- */

  if (message.type === "message") {
    return (
      <div className="message-row assistant-row">

        <div className="avatar agent-avatar">
          ⚙
        </div>

        <div className="message-content">

          <div className="message-name">
            Kubernetes Agent
          </div>

          <div className="assistant-text">
            {message.content}
          </div>

        </div>

      </div>
    );
  }


  /* ----------------------------------------- */
  /* ERROR */
  /* ----------------------------------------- */

  if (message.type === "error") {
    return (
      <div className="message-row assistant-row">

        <div className="avatar agent-avatar">
          ⚙
        </div>

        <div className="message-content">

          <div className="message-name">
            Kubernetes Agent
          </div>

          <div className="error-box">

            <div className="error-title">
              ⚠ Error
            </div>

            <div className="error-message">
              {message.content}
            </div>

          </div>

        </div>

      </div>
    );
  }


  /* ----------------------------------------- */
  /* KUBERNETES TOOL RESULT */
  /* ----------------------------------------- */

  if (message.type === "tool") {
    return (
      <div className="message-row assistant-row">

        <div className="avatar agent-avatar">
          ⚙
        </div>

        <div className="message-content">

          <div className="message-header">

            <div className="message-name">
              Kubernetes Agent
            </div>

            <div className="tool-name">
              {message.tool}
            </div>

          </div>

          <KubernetesResult result={message.result} />

        </div>

      </div>
    );
  }


  return null;
}


/* ========================================================= */
/* KUBERNETES RESULT */
/* ========================================================= */

function KubernetesResult({ result }) {

  if (!result) {
    return null;
  }

  const rows = result.rows || [];

  /* ----------------------------------------- */
  /* No resources */
  /* ----------------------------------------- */

  if (rows.length === 0) {
    return (
      <div className="result-card">

        <div className="result-title">
          {result.title || "Kubernetes Result"}
        </div>

        <div className="empty-result">
          {typeof result.summary === "string"
            ? result.summary
            : "No resources found."}
        </div>

      </div>
    );
  }


  /* ----------------------------------------- */
  /* Table */
  /* ----------------------------------------- */

  const columns = Object.keys(rows[0]);

  return (
    <div className="result-card">

      <div className="result-title">
        {result.title || "Kubernetes Result"}
      </div>

      <div className="table-container">

        <table>

          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column}>
                  {column}
                </th>
              ))}
            </tr>
          </thead>

          <tbody>

            {rows.map((row, rowIndex) => (
              <tr key={rowIndex}>

                {columns.map((column) => (
                  <td key={column}>
                    {String(row[column] ?? "")}
                  </td>
                ))}

              </tr>
            ))}

          </tbody>

        </table>

      </div>

      <div className="result-summary">

        {typeof result.summary === "object"
          ? `Total: ${result.summary.total ?? rows.length}`
          : result.summary}

      </div>

    </div>
  );
}

export default App;
