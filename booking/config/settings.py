from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    BEDRIJF_NAAM: str = "{{BEDRIJF_NAAM}}"
    BEDRIJF_PREFIX: str = "{{BEDRIJF_PREFIX}}"
    BEDRIJF_EMAIL: str = "{{BEDRIJF_EMAIL}}"
    BEDRIJF_URL: str = "{{BEDRIJF_URL}}"
    TIJDZONE: str = "Europe/Amsterdam"
    DATABASE_URL: str = "{{DATABASE_URL}}"
    JWT_SECRET: str = "{{JWT_SECRET}}"
    JWT_ALGORITME: str = "HS256"
    JWT_VERLOOPT_MINUTEN: int = 1440
    TOEGESTANE_ORIGINS: List[str] = ["{{FRONTEND_URL}}"]
    BETAAL_PROVIDER: str = "{{BETAAL_PROVIDER}}"
    MOLLIE_API_KEY: str = "{{MOLLIE_API_KEY}}"
    STRIPE_SECRET_KEY: str = "{{STRIPE_SECRET_KEY}}"
    SMTP_HOST: str = "{{SMTP_HOST}}"
    SMTP_PORT: int = 587
    SMTP_GEBRUIKER: str = "{{SMTP_GEBRUIKER}}"
    SMTP_WACHTWOORD: str = "{{SMTP_WACHTWOORD}}"
    SMS_ACTIEF: bool = False
    SMS_PROVIDER: str = "{{SMS_PROVIDER}}"
    SMS_API_KEY: str = "{{SMS_API_KEY}}"
    STORAGE_TYPE: str = "{{STORAGE_TYPE}}"
    S3_BUCKET: str = "{{S3_BUCKET}}"
    S3_REGIO: str = "{{S3_REGIO}}"
    S3_TOEGANG_KEY: str = "{{S3_TOEGANG_KEY}}"
    S3_GEHEIM_KEY: str = "{{S3_GEHEIM_KEY}}"
    AGENT_ACTIEF: bool = {{AGENT_ACTIEF}}
    AGENT_API_URL: str = "{{AGENT_API_URL}}"
    AGENT_TOKEN: str = "{{AGENT_TOKEN}}"

    class Config:
        env_file = ".env"

settings = Settings()
