FROM python:3.14-slim

# Install uv by copying the binary directly from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Prevent Python from writing .pyc files and enable unbuffered logging
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Copy dependency definition files first
COPY pyproject.toml uv.lock ./

# Install dependencies into the virtual environment (.venv)
RUN uv sync --frozen --no-dev --no-install-project

# Copy the application source code
COPY . .

# Step 3: Install the project itself into .venv
RUN uv sync --frozen --no-dev

# for documentation only
EXPOSE 8000

# RUN adduser --disabled-password --gecos "" appuser

# USER appuser

CMD ["uvicorn", "uptime.api:app", "--port", "8000", "--host", "0.0.0.0"]