from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    COMMUNITY_NAAM: str = "{{COMMUNITY_NAAM}}"
    COMMUNITY_EMAIL: str = "{{COMMUNITY_EMAIL}}"
    COMMUNITY_URL: str = "{{COMMUNITY_URL}}"
    COMMUNITY_BESCHRIJVING: str = "{{COMMUNITY_BESCHRIJVING}}"
    DATABASE_URL: str = "{{DATABASE_URL}}"
    REDIS_URL: str = "{{REDIS_URL}}"
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
    GAMIFICATION_ACTIEF: bool = True
    EVENEMENTEN_ACTIEF: bool = True
    BERICHTEN_ACTIEF: bool = True
    AGENT_ACTIEF: bool = {{AGENT_ACTIEF}}
    AGENT_API_URL: str = "{{AGENT_API_URL}}"
    AGENT_TOKEN: str = "{{AGENT_TOKEN}}"

    class Config:
        env_file = ".env"

settings = Settings()
