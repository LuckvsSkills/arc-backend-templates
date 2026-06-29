from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Winkel
    WINKEL_NAAM: str = "{{WINKEL_NAAM}}"
    WINKEL_PREFIX: str = "{{WINKEL_PREFIX}}"
    WINKEL_EMAIL: str = "{{WINKEL_EMAIL}}"
    WINKEL_URL: str = "{{WINKEL_URL}}"

    # Database
    DATABASE_URL: str = "{{DATABASE_URL}}"

    # Security
    JWT_SECRET: str = "{{JWT_SECRET}}"
    JWT_ALGORITME: str = "HS256"
    JWT_VERLOOPT_MINUTEN: int = 1440

    # CORS
    TOEGESTANE_ORIGINS: List[str] = ["{{FRONTEND_URL}}"]

    # Betaling
    MOLLIE_API_KEY: str = "{{MOLLIE_API_KEY}}"
    STRIPE_SECRET_KEY: str = "{{STRIPE_SECRET_KEY}}"
    BETAAL_PROVIDER: str = "{{BETAAL_PROVIDER}}"

    # Email
    SMTP_HOST: str = "{{SMTP_HOST}}"
    SMTP_PORT: int = 587
    SMTP_GEBRUIKER: str = "{{SMTP_GEBRUIKER}}"
    SMTP_WACHTWOORD: str = "{{SMTP_WACHTWOORD}}"

    # Storage
    STORAGE_TYPE: str = "{{STORAGE_TYPE}}"
    S3_BUCKET: str = "{{S3_BUCKET}}"
    S3_REGIO: str = "{{S3_REGIO}}"
    S3_TOEGANG_KEY: str = "{{S3_TOEGANG_KEY}}"
    S3_GEHEIM_KEY: str = "{{S3_GEHEIM_KEY}}"

    # Agent
    AGENT_ACTIEF: bool = {{AGENT_ACTIEF}}
    AGENT_API_URL: str = "{{AGENT_API_URL}}"
    AGENT_TOKEN: str = "{{AGENT_TOKEN}}"

    class Config:
        env_file = ".env"

settings = Settings()
