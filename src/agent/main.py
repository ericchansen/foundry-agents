import asyncio

from azure.ai.agentserver.responses import (
    CreateResponse,
    ResponseContext,
    ResponsesAgentServerHost,
    ResponsesServerOptions,
    TextResponse,
)
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

from settings import Settings

settings = Settings.from_env()
responses_client = None

if not settings.local_echo_mode:
    project_client = AIProjectClient(
        endpoint=settings.project_endpoint,
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

    if settings.local_echo_mode:
        return TextResponse(context, request, text=f"Echo: {user_input}")

    if responses_client is None:
        raise RuntimeError("The Foundry model client was not initialized.")

    response = await asyncio.get_running_loop().run_in_executor(
        None,
        lambda: responses_client.create(
            model=settings.model_deployment_name,
            instructions=settings.agent_instructions,
            input=[{"role": "user", "content": user_input}],
            store=False,
        ),
    )

    return TextResponse(context, request, text=response.output_text)


if __name__ == "__main__":
    app.run()
