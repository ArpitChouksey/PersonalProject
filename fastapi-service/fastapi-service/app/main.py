import contextlib

from fastapi import FastAPI

from app.api.calculator import router as calculator_router
from app.api.health import router as health_router
from app.api.system import router as system_router
from app.api.users import router as users_router
from app.config.settings import settings
from app.mcp.server import mcp
from app.ai.router import router as ai_router
from app.rag.router import router as rag_router
from app.ui.router import router as ui_router

from fastapi.staticfiles import StaticFiles

from app.ui.router import router as ui_router
from app.ui.router import STATIC_DIR

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    async with mcp.session_manager.run():
        yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)


app.include_router(health_router)
app.include_router(system_router)
app.include_router(calculator_router)
app.include_router(users_router)
app.include_router(ai_router)
app.include_router(rag_router)
app.include_router(ui_router)

app.mount(
    "/ui/static",
    StaticFiles(directory=STATIC_DIR),
    name="ui-static",
)

# MCP Streamable HTTP
app.mount(
    "/mcp",
    mcp.streamable_http_app(
        streamable_http_path="/",
    ),
)


@app.get("/")
def root():
    return {
        "service": settings.app_name,
        "status": "UP",
        "version": settings.app_version,
    }
