FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /srv
COPY pyproject.toml uv.lock* ./
RUN uv sync --no-dev --no-install-project --frozen || uv sync --no-dev --no-install-project
COPY . .
RUN uv sync --no-dev
ENV PATH=/srv/.venv/bin:$PATH
COPY --from=schemas . /srv/schemas
ENV UAVR_SCHEMA_DIR=/srv/schemas/feeds \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN useradd --uid 10001 --no-create-home uavr
USER 10001
EXPOSE 8000
CMD ["uvicorn", "uavr.main:app", "--host", "0.0.0.0", "--port", "8000"]
