from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, organisaties, leden,
    abonnementen, facturen, betalingen,
    api_sleutels, webhooks, gebruik,
    notificaties, admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from api.middleware.rate_limit import RateLimitMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"⚡ {settings.PLATFORM_NAAM} SaaS API gestart")
    yield

app = FastAPI(
    title=f"{settings.PLATFORM_NAAM} API",
    description="SaaS platform backend — ARC Template",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.TOEGESTANE_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(AuthMiddleware)
app.add_middleware(RateLimitMiddleware)

app.include_router(auth.router,          prefix="/api/v1/auth",          tags=["Authenticatie"])
app.include_router(gebruikers.router,    prefix="/api/v1/gebruikers",    tags=["Gebruikers"])
app.include_router(organisaties.router,  prefix="/api/v1/organisaties",  tags=["Organisaties"])
app.include_router(leden.router,         prefix="/api/v1/leden",         tags=["Leden"])
app.include_router(abonnementen.router,  prefix="/api/v1/abonnementen",  tags=["Abonnementen"])
app.include_router(facturen.router,      prefix="/api/v1/facturen",      tags=["Facturen"])
app.include_router(betalingen.router,    prefix="/api/v1/betalingen",    tags=["Betalingen"])
app.include_router(api_sleutels.router,  prefix="/api/v1/api-sleutels",  tags=["API Sleutels"])
app.include_router(webhooks.router,      prefix="/api/v1/webhooks",      tags=["Webhooks"])
app.include_router(gebruik.router,       prefix="/api/v1/gebruik",       tags=["Gebruik"])
app.include_router(notificaties.router,  prefix="/api/v1/notificaties",  tags=["Notificaties"])
app.include_router(instellingen.router,  prefix="/api/v1/instellingen",  tags=["Instellingen"])
app.include_router(admin.router,         prefix="/api/v1/admin",         tags=["Admin"])

@app.get("/")
async def root():
    return {"status": "online", "platform": settings.PLATFORM_NAAM, "versie": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "gezond"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
