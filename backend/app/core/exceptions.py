class AppException(Exception):
    def __init__(self, message: str, status_code: int = 400) -> None:
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class AuthenticationError(AppException):
    def __init__(self, message: str = "Could not validate credentials") -> None:
        super().__init__(message, status_code=401)


class NotFoundError(AppException):
    def __init__(self, message: str = "Resource not found") -> None:
        super().__init__(message, status_code=404)


class InferenceError(AppException):
    def __init__(self, message: str = "Model inference failed") -> None:
        super().__init__(message, status_code=503)
