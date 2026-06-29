from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, producten, categorieen,
    bestellingen, betalingen, kortingscodes,
    winkelwagen, reviews, media, admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from api.middleware.logging import LoggingMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 {settings.WINKEL_NAAM} API gestart")
    yield
    print("API afgesloten")

app = FastAPI(
    title=f"{settings.WINKEL_NAAM} API",
    description="E-commerce backend — ARC Template",
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
app.add_middleware(LoggingMiddleware)

# Routes
app.include_router(auth.router,          prefix="/api/v1/auth",          tags=["Authenticatie"])
app.include_router(gebruikers.router,    prefix="/api/v1/gebruikers",    tags=["Gebruikers"])
app.include_router(producten.router,     prefix="/api/v1/producten",     tags=["Producten"])
app.include_router(categorieen.router,   prefix="/api/v1/categorieen",   tags=["Categorieën"])
app.include_router(bestellingen.router,  prefix="/api/v1/bestellingen",  tags=["Bestellingen"])
app.include_router(betalingen.router,    prefix="/api/v1/betalingen",    tags=["Betalingen"])
app.include_router(kortingscodes.router, prefix="/api/v1/kortingscodes", tags=["Kortingscodes"])
app.include_router(winkelwagen.router,   prefix="/api/v1/winkelwagen",   tags=["Winkelwagen"])
app.include_router(reviews.router,       prefix="/api/v1/reviews",       tags=["Reviews"])
app.include_router(media.router,         prefix="/api/v1/media",         tags=["Media"])
app.include_router(instellingen.router,  prefix="/api/v1/instellingen",  tags=["Instellingen"])
app.include_router(admin.router,         prefix="/api/v1/admin",         tags=["Admin"])

@app.get("/")
async def root():
    return {"status": "online", "winkel": settings.WINKEL_NAAM, "versie": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "gezond"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
