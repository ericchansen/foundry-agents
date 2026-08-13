import asyncio
import os

from azure.ai.agentserver.responses import (
    CreateResponse,
    ResponseContext,
    ResponsesAgentServerHost,
    ResponsesServerOptions,
    TextResponse,
)
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

project_endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
model_deployment = os.environ["FOUNDRY_MODEL_NAME"]

project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=DefaultAzureCredential(),
)
responses_client = project_client.get_openai_client().responses

app = ResponsesAgentServerHost(
    options=ResponsesServerOptions(default_fetch_history_count=20),
)


@app.response_handler
async def handler(
    request: CreateResponse,
    context: ResponseContext,
    _cancellation_signal: asyncio.Event,
):
    user_input = await context.get_input_text() or "Hello!"
    response = await asyncio.get_running_loop().run_in_executor(
        None,
        lambda: responses_client.create(
            model=model_deployment,
            instructions="You are a concise learning assistant.",
            input=[{"role": "user", "content": user_input}],
            store=False,
        ),
    )
    return TextResponse(context, request, text=response.output_text)


if __name__ == "__main__":
    app.run()
