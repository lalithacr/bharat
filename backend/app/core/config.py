from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "Bharat Problem Solver AI"
    APP_VERSION: str = "1.0.0"
    APP_ENV: str = "development"

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    DATABASE_URL: str
    REDIS_URL: str = "redis://localhost:6379"

    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    GEMINI_API_KEY: str = ""

    AWS_ACCESS_KEY_ID: str = "dummy"
    AWS_SECRET_ACCESS_KEY: str = "dummy"
    AWS_BUCKET_NAME: str = "bharat-problem-solver-images"
    AWS_REGION: str = "ap-south-1"

    # Must match the key name in .env exactly
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    @property
    def origins_list(self) -> List[str]:
        if self.ALLOWED_ORIGINS.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()