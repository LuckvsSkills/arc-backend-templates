# ============================================
# ARC SECURITY — AUTHENTICATIE
# JWT tokens, wachtwoord hashing,
# rechten controle en sessie beheer
# ============================================

import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import Depends, HTTPException, Security, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext

# Wachtwoord hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def hash_wachtwoord(wachtwoord: str) -> str:
    return pwd_context.hash(wachtwoord)

def verifieer_wachtwoord(wachtwoord: str, hash: str) -> bool:
    return pwd_context.verify(wachtwoord, hash)

def valideer_wachtwoord_sterkte(wachtwoord: str) -> tuple[bool, str]:
    if len(wachtwoord) < 8:
        return False, "Wachtwoord moet minimaal 8 tekens bevatten"
    if not any(c.isupper() for c in wachtwoord):
        return False, "Wachtwoord moet minimaal één hoofdletter bevatten"
    if not any(c.islower() for c in wachtwoord):
        return False, "Wachtwoord moet minimaal één kleine letter bevatten"
    if not any(c.isdigit() for c in wachtwoord):
        return False, "Wachtwoord moet minimaal één cijfer bevatten"
    return True, ""

def maak_token(data: dict, secret: str, algoritme: str, verloop_minuten: int) -> str:
    te_encoderen = data.copy()
    verloopt = datetime.utcnow() + timedelta(minutes=verloop_minuten)
    te_encoderen.update({"exp": verloopt, "iat": datetime.utcnow()})
    return jwt.encode(te_encoderen, secret, algorithm=algoritme)

def verifieer_token(token: str, secret: str, algoritme: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, secret, algorithms=[algoritme])
        return payload
    except JWTError:
        return None

def genereer_veilige_token(lengte: int = 32) -> str:
    return secrets.token_urlsafe(lengte)

def hash_api_sleutel(sleutel: str) -> str:
    return hashlib.sha256(sleutel.encode()).hexdigest()

class AuthMiddleware:
    OPENBARE_PADEN = [
        "/", "/health", "/docs", "/redoc", "/openapi.json",
        "/api/v1/auth/login", "/api/v1/auth/registreer",
        "/api/v1/auth/wachtwoord-reset", "/api/v1/auth/verifieer-email",
        "/api/v1/producten", "/api/v1/artikelen", "/api/v1/diensten",
        "/api/v1/evenementen", "/api/v1/groepen",
    ]

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            pad = scope.get("path", "")
            if not any(pad.startswith(open_pad) for open_pad in self.OPENBARE_PADEN):
                pass  # Token validatie via dependency injection in routes
        await self.app(scope, receive, send)

def vereist_auth(credentials: HTTPAuthorizationCredentials = Security(security)):
    from config.settings import settings
    token = credentials.credentials
    payload = verifieer_token(token, settings.JWT_SECRET, settings.JWT_ALGORITME)
    if not payload:
        raise HTTPException(status_code=401, detail="Ongeldige of verlopen sessie")
    return payload

def vereist_rol(toegestane_rollen: List[str]):
    def check_rol(payload: dict = Depends(vereist_auth)):
        gebruiker_rol = payload.get("rol", "")
        if gebruiker_rol not in toegestane_rollen:
            raise HTTPException(status_code=403, detail="Onvoldoende rechten")
        return payload
    return check_rol

vereist_admin = vereist_rol(["admin"])
vereist_moderator = vereist_rol(["admin", "moderator"])
vereist_medewerker = vereist_rol(["admin", "medewerker"])
