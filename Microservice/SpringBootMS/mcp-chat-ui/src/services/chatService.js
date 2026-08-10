const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "/api";

const AI_API_URL = `${API_BASE_URL}/ai/chat`;

export async function sendMessage(message) {
    const response = await fetch(
        `${AI_API_URL}?message=${encodeURIComponent(message)}`
    );

    if (!response.ok) {
        throw new Error(`Request failed: ${response.status}`);
    }

    return response.text();
}
