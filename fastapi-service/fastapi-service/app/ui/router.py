from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse


router = APIRouter(
    prefix="/ui",
    tags=["UI"],
)


BASE_DIR = Path(__file__).resolve().parent

STATIC_DIR = BASE_DIR / "static"


@router.get("")
async def ui():

    return FileResponse(
        STATIC_DIR / "index.html"
    )
