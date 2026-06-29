from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from api.routes import (
    auth, gebruikers, artikelen, categorieen,
    tags, paginas, media, commentaren,
    nieuwsbrief, menu, seo, admin, instellingen
)
from api.middleware.auth import AuthMiddleware
from config.settings import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"📝 {settings.SITE_NAAM} Content API gestart")
    yield

app = FastAPI(
    title=f"{settings.SITE_NAAM} Content API",
    description="Content/Blog backend — ARC Template",
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
app.include_router(artikelen.router,    prefix="/api/v1/artikelen",     tags=["Artikelen"])
app.include_router(categorieen.router,  prefix="/api/v1/categorieen",   tags=["Categorieën"])
app.include_router(tags.router,         prefix="/api/v1/tags",          tags=["Tags"])
app.include_router(paginas.router,      prefix="/api/v1/paginas",       tags=["Pagina's"])
app.include_router(media.router,        prefix="/api/v1/media",         tags=["Media"])
app.include_router(commentaren.router,  prefix="/api/v1/commentaren",   tags=["Commentaren"])
app.include_router(nieuwsbrief.router,  prefix="/api/v1/nieuwsbrief",   tags=["Nieuwsbrief"])
app.include_router(menu.router,         prefix="/api/v1/menu",          tags=["Menu"])
app.include_router(seo.router,          prefix="/api/v1/seo",           tags=["SEO"])
app.include_router(instellingen.router, prefix="/api/v1/instellingen",  tags=["Instellingen"])
app.include_router(admin.router,        prefix="/api/v1/admin",         tags=["Admin"])

@app.get("/")
async def root():
    return {"status": "online", "site": settings.SITE_NAAM, "versie": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "gezond"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
