import { useState } from "react";

function App() {
  const [message, setMessage] = useState("");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const sendMessage = async () => {
    if (!message.trim()) {
      return;
    }

    setLoading(true);
    setResult(null);

    try {
      const response = await fetch(
        "http://localhost:8000/agent/chat",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message,
          }),
        }
      );

      const data = await response.json();

      setResult(data);
    } catch (error) {
      setResult({
        status: "ERROR",
        message: error.message,
      });
    } finally {
      setLoading(false);
    }
  };

  const renderTable = () => {
    if (
      !result?.data ||
      !Array.isArray(result.data) ||
      result.data.length === 0
    ) {
      return null;
    }

    const columns =
      result.columns ||
      Object.keys(result.data[0]);

    return (
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column}>
                  {column.toUpperCase()}
                </th>
              ))}
            </tr>
          </thead>

          <tbody>
            {result.data.map(
              (row, index) => (
                <tr key={index}>
                  {columns.map(
                    (column) => (
                      <td key={column}>
                        {String(
                          row[column] ?? ""
                        )}
                      </td>
                    )
                  )}
                </tr>
              )
            )}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <div className="app">

      <h1>Docker Agent</h1>

      <p>
        Ask about Docker containers,
        images or Linux processes.
      </p>

      <div className="input-row">

        <input
          value={message}
          onChange={(e) =>
            setMessage(e.target.value)
          }
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              sendMessage();
            }
          }}
          placeholder="Show container name and status"
        />

        <button
          onClick={sendMessage}
          disabled={loading}
        >
          {loading
            ? "Loading..."
            : "Send"}
        </button>

      </div>

      {result && (
        <div className="result">

          <h2>Result</h2>

          {result.status === "ERROR" ? (
            <div className="error">
              {result.message}
            </div>
          ) : (
            <>
              {renderTable()}

              {(!result.data ||
                result.data.length === 0) && (
                <pre>
                  {result.message}
                </pre>
              )}
            </>
          )}

        </div>
      )}

      <style>{`

        .app {
          max-width: 1200px;
          margin: 40px auto;
          padding: 20px;
          font-family: Arial, sans-serif;
        }

        .input-row {
          display: flex;
          gap: 10px;
          margin: 25px 0;
        }

        input {
          flex: 1;
          padding: 12px;
          font-size: 16px;
          border: 1px solid #ccc;
          border-radius: 6px;
        }

        button {
          padding: 12px 24px;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-size: 16px;
        }

        button:disabled {
          cursor: not-allowed;
        }

        .table-wrapper {
          overflow-x: auto;
          margin-top: 20px;
        }

        table {
          width: 100%;
          border-collapse: collapse;
        }

        th,
        td {
          padding: 12px;
          border: 1px solid #ddd;
          text-align: left;
          white-space: nowrap;
        }

        th {
          font-weight: bold;
        }

        tr:nth-child(even) {
          background: #f7f7f7;
        }

        .error {
          padding: 15px;
          border-radius: 6px;
        }

        pre {
          white-space: pre-wrap;
          padding: 15px;
          border-radius: 6px;
        }

      `}</style>

    </div>
  );
}

export default App;
