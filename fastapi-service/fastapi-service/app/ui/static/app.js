const messageInput =
    document.getElementById("messageInput");

const sendButton =
    document.getElementById("sendButton");

const messages =
    document.getElementById("messages");

const statusText =
    document.getElementById("statusText");


async function checkHealth() {

    try {

        const response =
            await fetch("/health");

        if (!response.ok) {

            throw new Error(
                "Health check failed"
            );
        }

        const data =
            await response.json();

        if (data.status === "UP") {

            statusText.textContent =
                "Service UP";
        }

    } catch (error) {

        statusText.textContent =
            "Service DOWN";
    }
}


function addMessage(
    role,
    text
) {

    const message =
        document.createElement("div");

    message.className =
        `message ${role}`;

    const label =
        document.createElement("div");

    label.className =
        "message-label";

    label.textContent =
        role === "user"
            ? "You"
            : "AI Assistant";


    const content =
        document.createElement("div");

    content.className =
        "message-content";

    content.textContent =
        text;


    message.appendChild(label);

    message.appendChild(content);

    messages.appendChild(message);

    messages.scrollTop =
        messages.scrollHeight;
}


async function sendMessage() {

    const message =
        messageInput.value.trim();

    if (!message) {

        return;
    }


    addMessage(
        "user",
        message
    );


    messageInput.value = "";

    sendButton.disabled = true;

    sendButton.textContent =
        "Thinking...";


    try {

        const response =
            await fetch(
                "/ai/chat",
                {
                    method: "POST",

                    headers: {
                        "Content-Type":
                            "application/json"
                    },

                    body: JSON.stringify({
                        message: message
                    })
                }
            );


        if (!response.ok) {

            const error =
                await response.text();

            throw new Error(error);
        }


        const data =
            await response.json();


        addMessage(
            "assistant",
            data.response
        );


    } catch (error) {

        addMessage(
            "assistant",
            "Error: " +
            error.message
        );

    } finally {

        sendButton.disabled =
            false;

        sendButton.textContent =
            "Send";
    }
}


function useExample(text) {

    messageInput.value =
        text;

    messageInput.focus();
}


messageInput.addEventListener(
    "keydown",
    function(event) {

        if (
            event.key === "Enter" &&
            !event.shiftKey
        ) {

            event.preventDefault();

            sendMessage();
        }
    }
);


checkHealth();
