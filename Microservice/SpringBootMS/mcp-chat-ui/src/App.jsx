import { useState } from "react";
import { sendMessage } from "./services/chatService";
import "./App.css";

function App() {

    const [messages, setMessages] = useState([]);
    const [input, setInput] = useState("");
    const [loading, setLoading] = useState(false);

    const handleSend = async () => {

        const message = input.trim();

        if (!message || loading) {
            return;
        }

        setMessages((previous) => [
            ...previous,
            {
                role: "user",
                content: message
            }
        ]);

        setInput("");
        setLoading(true);

        try {

            const response = await sendMessage(message);

            setMessages((previous) => [
                ...previous,
                {
                    role: "assistant",
                    content: response
                }
            ]);

        } catch (error) {

            setMessages((previous) => [
                ...previous,
                {
                    role: "assistant",
                    content: `Error: ${error.message}`
                }
            ]);

        } finally {

            setLoading(false);
        }
    };

    const handleKeyDown = (event) => {

        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault();
            handleSend();
        }
    };

    return (
        <div className="app">

            <header className="header">
                <div>
                    <h1>MCP Custom CRUD Assistant</h1>
                    <p>AI + MCP + Spring Boot</p>
                </div>
            </header>

            <main className="chat-container">

                <div className="messages">

                    {messages.length === 0 && (
                        <div className="welcome">

                            <h2>How can I help?</h2>

                            <p>
                                Ask me to create users or interact with
                                the MCP tools.
                            </p>

                            <div className="examples">

                                <button
                                    onClick={() =>
                                        setInput(
                                            "Use the hello tool and tell me its result"
                                        )
                                    }
                                >
                                    Test MCP
                                </button>

                                <button
                                    onClick={() =>
                                        setInput(
                                            "Create a user named Arpit with email arpit@example.com"
                                        )
                                    }
                                >
                                    Create User
                                </button>

                            </div>

                        </div>
                    )}

                    {messages.map((message, index) => (

                        <div
                            key={index}
                            className={`message-row ${message.role}`}
                        >

                            <div className="message">

                                <div className="message-role">
                                    {message.role === "user"
                                        ? "You"
                                        : "MCP Assistant"}
                                </div>

                                <div className="message-content">
                                    {message.content}
                                </div>

                            </div>

                        </div>

                    ))}

                    {loading && (
                        <div className="message-row assistant">

                            <div className="message">

                                <div className="message-role">
                                    MCP Assistant
                                </div>

                                <div className="typing">
                                    Thinking...
                                </div>

                            </div>

                        </div>
                    )}

                </div>

                <div className="input-container">

                    <textarea
                        value={input}
                        onChange={(event) =>
                            setInput(event.target.value)
                        }
                        onKeyDown={handleKeyDown}
                        placeholder="Ask something..."
                        rows="1"
                        disabled={loading}
                    />

                    <button
                        onClick={handleSend}
                        disabled={!input.trim() || loading}
                    >
                        Send
                    </button>

                </div>

                <div className="footer">
                    Powered by Ollama • Spring AI • MCP
                </div>

            </main>

        </div>
    );
}

export default App;
