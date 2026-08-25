const API_BASE_URL =
  "http://127.0.0.1:8000";


// ============================================================
// SEND CHAT MESSAGE
// ============================================================

export async function sendMessage(
  message
) {

  const response = await fetch(
    `${API_BASE_URL}/agent/chat`,
    {
      method: "POST",

      headers: {
        "Content-Type":
          "application/json",
      },

      body: JSON.stringify({
        message,
      }),
    }
  );


  if (!response.ok) {

    throw new Error(
      `Backend returned ${response.status}`
    );

  }


  return await response.json();

}


// ============================================================
// APPROVE OPERATION
// ============================================================

export async function approveOperation(
  tool,
  parameters,
  approved
) {

  const response = await fetch(
    `${API_BASE_URL}/agent/approve`,
    {
      method: "POST",

      headers: {
        "Content-Type":
          "application/json",
      },

      body: JSON.stringify({

        tool,

        parameters:
          parameters || {},

        approved,

      }),
    }
  );


  if (!response.ok) {

    throw new Error(
      `Approval API returned ${response.status}`
    );

  }


  return await response.json();

}
