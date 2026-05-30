from typing import Any

from fastapi.responses import JSONResponse


def error_response(message: str, status_code: int = 400) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"success": False, "message": message},
    )


def success_response(data: dict[str, Any] | None = None, status_code: int = 200) -> JSONResponse:
    content: dict[str, Any] = {"success": True}
    if data:
        content.update(data)
    return JSONResponse(status_code=status_code, content=content)
