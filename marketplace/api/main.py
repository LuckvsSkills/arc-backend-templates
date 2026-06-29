from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, verkopers, categorieen,
    advertenties, transacties, betalingen,
    uitbetalingen, berichten, beoordelingen,
    meldingen, zoeken, admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🏪 {settings.PLATFORM_NAAM} Marketplace API gestart")
    yield

app = FastAPI(
    title=f"{settings.PLATFORM_NAAM} Marketplace API",
    description="Marketplace backend — ARC Template",
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

app.include_router(auth.router,          prefix="/api/v1/auth",          tags=["Authenticatie"])
app.include_router(gebruikers.router,    prefix="/api/v1/gebruikers",    tags=["Gebruikers"])
app.include_router(verkopers.router,     prefix="/api/v1/verkopers",     tags=["Verkopers"])
app.include_router(categorieen.router,   prefix="/api/v1/categorieen",   tags=["Categorieën"])
app.include_router(advertenties.router,  prefix="/api/v1/advertenties",  tags=["Advertenties"])
app.include_router(transacties.router,   prefix="/api/v1/transacties",   tags=["Transacties"])
app.include_router(betalingen.router,    prefix="/api/v1/betalingen",    tags=["Betalingen"])
app.include_router(uitbetalingen.router, prefix="/api/v1/uitbetalingen", tags=["Uitbetalingen"])
app.include_router(berichten.router,     prefix="/api/v1/berichten",     tags=["Berichten"])
app.include_router(beoordelingen.router, prefix="/api/v1/beoordelingen", tags=["Beoordelingen"])
app.include_router(meldingen.router,     prefix="/api/v1/meldingen",     tags=["Meldingen"])
app.include_router(zoeken.router,        prefix="/api/v1/zoeken",        tags=["Zoeken"])
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
