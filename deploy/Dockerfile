FROM python:3.12-slim

WORKDIR /app

# System deps (none required beyond base) — kept slim.
COPY backend/pyproject.toml /app/backend/pyproject.toml
COPY backend/__init__.py /app/backend/__init__.py
COPY backend/app /app/backend/app
COPY sim /app/sim
COPY scenarios /app/scenarios

# Install runtime deps
RUN pip install --no-cache-dir \
      fastapi==0.115.0 \
      "uvicorn[standard]==0.30.6" \
      pydantic==2.7.4 \
      scipy==1.13.1 \
      numpy==1.26.4 \
      websockets==12.0 \
      python-multipart==0.0.9

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PORT=8080

EXPOSE 8080

CMD ["uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8080"]
