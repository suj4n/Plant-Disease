"""Application exceptions carrying a machine-readable error code.

Clients switch on ``error_code``; ``message`` is for logs and as a fallback.
"""


class ErrorCode:
    INVALID_IMAGE = "INVALID_IMAGE"
    FILE_TOO_LARGE = "FILE_TOO_LARGE"
    MODEL_UNAVAILABLE = "MODEL_UNAVAILABLE"
    PREDICTION_FAILED = "PREDICTION_FAILED"
    UNAUTHORIZED = "UNAUTHORIZED"
    NOT_FOUND = "NOT_FOUND"
    DATABASE_ERROR = "DATABASE_ERROR"
    VALIDATION_ERROR = "VALIDATION_ERROR"
    RATE_LIMITED = "RATE_LIMITED"
    INTERNAL_ERROR = "INTERNAL_ERROR"


class AppException(Exception):
    error_code: str = ErrorCode.INTERNAL_ERROR

    def __init__(
        self,
        message: str,
        status_code: int = 400,
        error_code: str | None = None,
    ) -> None:
        self.message = message
        self.status_code = status_code
        if error_code is not None:
            self.error_code = error_code
        super().__init__(message)


class AuthenticationError(AppException):
    error_code = ErrorCode.UNAUTHORIZED

    def __init__(self, message: str = "Could not validate credentials") -> None:
        super().__init__(message, status_code=401)


class NotFoundError(AppException):
    error_code = ErrorCode.NOT_FOUND

    def __init__(self, message: str = "Resource not found") -> None:
        super().__init__(message, status_code=404)


class InvalidImageError(AppException):
    error_code = ErrorCode.INVALID_IMAGE

    def __init__(self, message: str = "The uploaded image could not be processed.") -> None:
        super().__init__(message, status_code=400)


class FileTooLargeError(AppException):
    error_code = ErrorCode.FILE_TOO_LARGE

    def __init__(self, message: str = "The uploaded file is too large.") -> None:
        super().__init__(message, status_code=413)


class InferenceError(AppException):
    error_code = ErrorCode.PREDICTION_FAILED

    def __init__(self, message: str = "Model inference failed") -> None:
        super().__init__(message, status_code=503)


class ModelUnavailableError(AppException):
    error_code = ErrorCode.MODEL_UNAVAILABLE

    def __init__(self, message: str = "The detection model is not available yet.") -> None:
        super().__init__(message, status_code=503)
