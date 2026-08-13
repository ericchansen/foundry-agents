FROM python:3.13-slim

RUN addgroup --system agent \
    && adduser --system --ingroup agent --home /home/agent agent

USER agent

EXPOSE 8088

CMD ["python", "-m", "http.server", "9090"]
