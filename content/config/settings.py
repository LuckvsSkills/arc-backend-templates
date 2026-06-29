from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    SITE_NAAM: str = "{{SITE_NAAM}}"
    SITE_EMAIL: str = "{{SITE_EMAIL}}"
    SITE_URL: str = "{{SITE_URL}}"
    SITE_BESCHRIJVING: str = "{{SITE_BESCHRIJVING}}"
    DATABASE_URL: str = "{{DATABASE_URL}}"
    JWT_SECRET: str = "{{JWT_SECRET}}"
    JWT_ALGORITME: str = "HS256"
    JWT_VERLOOPT_MINUTEN: int = 1440
    TOEGESTANE_ORIGINS: List[str] = ["{{FRONTEND_URL}}"]
    SMTP_HOST: str = "{{SMTP_HOST}}"
    SMTP_PORT: int = 587
    SMTP_GEBRUIKER: str = "{{SMTP_GEBRUIKER}}"
    SMTP_WACHTWOORD: str = "{{SMTP_WACHTWOORD}}"
    STORAGE_TYPE: str = "{{STORAGE_TYPE}}"
    S3_BUCKET: str = "{{S3_BUCKET}}"
    S3_REGIO: str = "{{S3_REGIO}}"
    S3_TOEGANG_KEY: str = "{{S3_TOEGANG_KEY}}"
    S3_GEHEIM_KEY: str = "{{S3_GEHEIM_KEY}}"
    GA_ID: str = "{{GA_ID}}"
    AGENT_ACTIEF: bool = {{AGENT_ACTIEF}}
    AGENT_API_URL: str = "{{AGENT_API_URL}}"
    AGENT_TOKEN: str = "{{AGENT_TOKEN}}"

    class Config:
        env_file = ".env"

settings = Settings()
