from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PLATFORM_NAAM: str = "{{PLATFORM_NAAM}}"
    PLATFORM_PREFIX: str = "{{PLATFORM_PREFIX}}"
    PLATFORM_EMAIL: str = "{{PLATFORM_EMAIL}}"
    PLATFORM_URL: str = "{{PLATFORM_URL}}"
    DATABASE_URL: str = "{{DATABASE_URL}}"
    REDIS_URL: str = "{{REDIS_URL}}"
    JWT_SECRET: str = "{{JWT_SECRET}}"
    JWT_ALGORITME: str = "HS256"
    JWT_VERLOOPT_MINUTEN: int = 1440
    TOEGESTANE_ORIGINS: List[str] = ["{{FRONTEND_URL}}"]
    API_RATE_LIMIT: int = 1000
    BETAAL_PROVIDER: str = "{{BETAAL_PROVIDER}}"
    MOLLIE_API_KEY: str = "{{MOLLIE_API_KEY}}"
    STRIPE_SECRET_KEY: str = "{{STRIPE_SECRET_KEY}}"
    STRIPE_WEBHOOK_SECRET: str = "{{STRIPE_WEBHOOK_SECRET}}"
    SMTP_HOST: str = "{{SMTP_HOST}}"
    SMTP_PORT: int = 587
    SMTP_GEBRUIKER: str = "{{SMTP_GEBRUIKER}}"
    SMTP_WACHTWOORD: str = "{{SMTP_WACHTWOORD}}"
    STORAGE_TYPE: str = "{{STORAGE_TYPE}}"
    S3_BUCKET: str = "{{S3_BUCKET}}"
    S3_REGIO: str = "{{S3_REGIO}}"
    S3_TOEGANG_KEY: str = "{{S3_TOEGANG_KEY}}"
    S3_GEHEIM_KEY: str = "{{S3_GEHEIM_KEY}}"
    PROEFPERIODE_DAGEN: int = 14
    PRIJS_STARTER: float = {{PRIJS_STARTER}}
    PRIJS_PRO: float = {{PRIJS_PRO}}
    AGENT_ACTIEF: bool = {{AGENT_ACTIEF}}
    AGENT_API_URL: str = "{{AGENT_API_URL}}"
    AGENT_TOKEN: str = "{{AGENT_TOKEN}}"

    class Config:
        env_file = ".env"

settings = Settings()
