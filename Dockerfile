FROM debian:bookworm-slim AS builder

# Install uv by copying the binary directly from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Prevent Python from writing .pyc files and enable unbuffered logging.
# Use a uv-managed Python installed at a fixed path so it can be copied into
# the distroless runtime (distroless/python3 only ships Python 3.11).
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON=3.14 \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_PYTHON_INSTALL_DIR=/python \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app
# Ensure uv creates the virtualenv at /app/.venv
ENV UV_PROJECT_ENVIRONMENT="/app/.venv"

RUN uv python install \
    # psycopg[binary] needs libz, which distroless/cc doesn't ship
    && mkdir -p /runtime-libs \
    && cp -L /lib/$(uname -m)-linux-gnu/libz.so.1 /runtime-libs/

# Copy dependency definition files first
COPY pyproject.toml uv.lock ./

# Install dependencies into the virtual environment (.venv)
RUN uv sync --frozen --no-dev --no-install-project

# Copy the application source code
COPY . .

# Step 3: Install the project itself into .venv
RUN uv sync --frozen --no-dev

FROM gcr.io/distroless/cc-debian12 AS runtime

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# The venv's python symlink points into /python, so copy it to the same path
COPY --from=builder /python /python
COPY --from=builder /runtime-libs/ /usr/lib/
COPY --from=builder /app /app

# for documentation only
EXPOSE 8000

USER nonroot

CMD ["uvicorn", "uptime.api:app", "--port", "8000", "--host", "0.0.0.0"]
