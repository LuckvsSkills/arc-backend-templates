from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, diensten, categorieen,
    medewerkers, beschikbaarheid, reserveringen,
    betalingen, reviews, notificaties, wachtlijst,
    admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🗓️ {settings.BEDRIJF_NAAM} Booking API gestart")
    yield

app = FastAPI(
    title=f"{settings.BEDRIJF_NAAM} Booking API",
    description="Booking backend — ARC Template",
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

app.include_router(auth.router,           prefix="/api/v1/auth",           tags=["Authenticatie"])
app.include_router(gebruikers.router,     prefix="/api/v1/gebruikers",     tags=["Gebruikers"])
app.include_router(diensten.router,       prefix="/api/v1/diensten",       tags=["Diensten"])
app.include_router(categorieen.router,    prefix="/api/v1/categorieen",    tags=["Categorieën"])
app.include_router(medewerkers.router,    prefix="/api/v1/medewerkers",    tags=["Medewerkers"])
app.include_router(beschikbaarheid.router,prefix="/api/v1/beschikbaarheid",tags=["Beschikbaarheid"])
app.include_router(reserveringen.router,  prefix="/api/v1/reserveringen",  tags=["Reserveringen"])
app.include_router(betalingen.router,     prefix="/api/v1/betalingen",     tags=["Betalingen"])
app.include_router(reviews.router,        prefix="/api/v1/reviews",        tags=["Reviews"])
app.include_router(notificaties.router,   prefix="/api/v1/notificaties",   tags=["Notificaties"])
app.include_router(wachtlijst.router,     prefix="/api/v1/wachtlijst",     tags=["Wachtlijst"])
app.include_router(instellingen.router,   prefix="/api/v1/instellingen",   tags=["Instellingen"])
app.include_router(admin.router,          prefix="/api/v1/admin",          tags=["Admin"])

@app.get("/")
async def root():
    return {"status": "online", "bedrijf": settings.BEDRIJF_NAAM, "versie": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "gezond"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
