FROM python:3.13-slim

ARG PIP_INDEX_URL=https://pypi.org/simple

ENV HOME=/home/agent \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN python -m pip install --index-url "${PIP_INDEX_URL}" \
    --requirement requirements.txt

RUN addgroup --system agent \
    && adduser --system --ingroup agent --home /home/agent agent

COPY --chown=agent:agent main.py .

USER agent

EXPOSE 8088

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8088/readiness', timeout=2)"]

CMD ["python", "main.py"]
