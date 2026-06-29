from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, groepen, posts,
    reacties, likes, berichten, evenementen,
    notificaties, badges, meldingen,
    zoeken, admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"👥 {settings.COMMUNITY_NAAM} Community API gestart")
    yield

app = FastAPI(
    title=f"{settings.COMMUNITY_NAAM} API",
    description="Community backend — ARC Template",
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

app.include_router(auth.router,         prefix="/api/v1/auth",          tags=["Authenticatie"])
app.include_router(gebruikers.router,   prefix="/api/v1/gebruikers",    tags=["Gebruikers"])
app.include_router(groepen.router,      prefix="/api/v1/groepen",       tags=["Groepen"])
app.include_router(posts.router,        prefix="/api/v1/posts",         tags=["Posts"])
app.include_router(reacties.router,     prefix="/api/v1/reacties",      tags=["Reacties"])
app.include_router(likes.router,        prefix="/api/v1/likes",         tags=["Likes"])
app.include_router(berichten.router,    prefix="/api/v1/berichten",     tags=["Berichten"])
app.include_router(evenementen.router,  prefix="/api/v1/evenementen",   tags=["Evenementen"])
app.include_router(notificaties.router, prefix="/api/v1/notificaties",  tags=["Notificaties"])
app.include_router(badges.router,       prefix="/api/v1/badges",        tags=["Badges"])
app.include_router(meldingen.router,    prefix="/api/v1/meldingen",     tags=["Meldingen"])
app.include_router(zoeken.router,       prefix="/api/v1/zoeken",        tags=["Zoeken"])
app.include_router(instellingen.router, prefix="/api/v1/instellingen",  tags=["Instellingen"])
app.include_router(admin.router,        prefix="/api/v1/admin",         tags=["Admin"])

@app.get("/")
async def root():
    return {"status": "online", "community": settings.COMMUNITY_NAAM, "versie": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "gezond"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
