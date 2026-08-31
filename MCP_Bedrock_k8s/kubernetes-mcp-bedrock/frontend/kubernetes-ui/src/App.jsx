import { useState } from "react";
import "./App.css";

const API_URL = "http://127.0.0.1:8000/api/chat";

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  const exampleQueries = [
    "List all namespaces",
    "List all pods",
    "Pods in kube-system",
    "Pod status",
    "Show pod logs",
  ];

  const sendMessage = async (message = input) => {
    const text = message.trim();

    if (!text || loading) {
      return;
    }

    // Add user message immediately
    setMessages((prev) => [
      ...prev,
      {
        role: "user",
        content: text,
      },
    ]);

    setInput("");
    setLoading(true);

    try {
      console.log("[UI] Sending request to:", API_URL);
      console.log("[UI] Message:", text);

      const response = await fetch(API_URL, {
        method: "POST",

        headers: {
          "Content-Type": "application/json",
        },

        body: JSON.stringify({
          message: text,
        }),
      });

      console.log("[UI] HTTP status:", response.status);

      if (!response.ok) {
        throw new Error(
          `Backend returned HTTP ${response.status}`
        );
      }

      const data = await response.json();

      console.log("[UI] Backend response:", data);

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            data.response ||
            "The agent returned an empty response.",
        },
      ]);
    } catch (error) {
      console.error("[UI] Request failed:", error);

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `Error: ${error.message || "Failed to fetch"}`,
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

      {/* =====================================================
          Header
      ====================================================== */}

      <header className="header">

        <div>
          <h1>⚙ Kubernetes AI Agent</h1>

          <p>
            Bedrock + MCP + Kubernetes
          </p>
        </div>

        <div className="connection-status">
          <span className="status-dot"></span>
          MCP Connected
        </div>

      </header>


      {/* =====================================================
          Main Layout
      ====================================================== */}

      <div className="main-layout">

        {/* ===================================================
            Sidebar
        ==================================================== */}

        <aside className="sidebar">

          <h2>Cluster</h2>

          <div className="info-card">
            <span>Kubernetes</span>
            <strong>docker-desktop</strong>
          </div>

          <div className="info-card">
            <span>MCP Server</span>
            <strong>127.0.0.1:8080</strong>
          </div>

          <div className="info-card">
            <span>Model</span>
            <strong>Nova Lite</strong>
          </div>

          <div className="info-card">
            <span>Mode</span>
            <strong>🔒 Read-only</strong>
          </div>


          {/* =================================================
              Example Queries
          ================================================== */}

          <h2 className="example-title">
            Example queries
          </h2>

          <div className="examples">

            {exampleQueries.map((query) => (
              <button
                key={query}
                onClick={() => sendMessage(query)}
                disabled={loading}
              >
                {query}
              </button>
            ))}

          </div>

        </aside>


        {/* ===================================================
            Chat Area
        ==================================================== */}

        <main className="chat-area">

          {/* Chat Header */}

          <div className="chat-header">

            <h2>
              Kubernetes Assistant
            </h2>

            <p>
              Ask questions about your cluster
            </p>

          </div>


          {/* =================================================
              Messages
          ================================================== */}

          <div className="messages">

            {messages.length === 0 && (
              <div className="empty-state">
                Ask something about your Kubernetes cluster.
              </div>
            )}

            {messages.map((message, index) => (

              <div
                key={index}
                className={`message ${
                  message.role === "user"
                    ? "user-message"
                    : "assistant-message"
                }`}
              >

                <div className="avatar">

                  {message.role === "user"
                    ? "U"
                    : "⚙"}

                </div>

                <div className="message-content">

                  <div className="message-name">

                    {message.role === "user"
                      ? "You"
                      : "Kubernetes Agent"}

                  </div>

                  <div className="message-text">

                    <pre>
                      {message.content}
                    </pre>

                  </div>

                </div>

              </div>

            ))}


            {/* Loading */}

            {loading && (
              <div className="message assistant-message">

                <div className="avatar">
                  ⚙
                </div>

                <div className="message-content">

                  <div className="message-name">
                    Kubernetes Agent
                  </div>

                  <div className="message-text">
                    Thinking...
                  </div>

                </div>

              </div>
            )}

          </div>


          {/* =================================================
              Input
          ================================================== */}

          <div className="input-area">

            <input
              type="text"
              placeholder="Ask Kubernetes something..."
              value={input}
              onChange={(event) =>
                setInput(event.target.value)
              }
              onKeyDown={handleKeyDown}
              disabled={loading}
            />

            <button
              onClick={() => sendMessage()}
              disabled={!input.trim() || loading}
            >
              {loading ? "..." : "Send"}
            </button>

          </div>


          <div className="footer-note">
            Read-only Kubernetes access
          </div>

        </main>

      </div>

    </div>
  );
}

export default App;
