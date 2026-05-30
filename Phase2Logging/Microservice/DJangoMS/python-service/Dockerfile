# ---------- STAGE 1: Builder ----------
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

# Copy dependency file
COPY requirements.txt .

# Create virtual environment and install deps
RUN python -m venv /venv \
    && /venv/bin/pip install --upgrade pip \
    && /venv/bin/pip install -r requirements.txt


# ---------- STAGE 2: Runtime ----------
FROM python:3.12-slim

WORKDIR /app

# Copy virtualenv from builder
COPY --from=builder /venv /venv

# Copy application code
COPY . .

# Activate virtualenv
ENV PATH="/venv/bin:$PATH"

# Expose Django port
EXPOSE 8000

# Run Django app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

