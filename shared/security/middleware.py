# ============================================
# ARC SECURITY — MIDDLEWARE
# Rate limiting, CORS, security headers,
# request validatie en logging
# ============================================

import time
import hashlib
from collections import defaultdict
from typing import Callable
from fastapi import Request, Response, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from .sanitizer import bevat_sql_injectie, bevat_xss

# ============================================
# RATE LIMITER
# ============================================

class RateLimiter:
    def __init__(self):
        self.verzoeken: dict = defaultdict(list)
        self.geblokkeerd: dict = {}

    def is_geblokkeerd(self, ip: str) -> bool:
        if ip in self.geblokkeerd:
            if time.time() < self.geblokkeerd[ip]:
                return True
            else:
                del self.geblokkeerd[ip]
        return False

    def registreer_verzoek(self, ip: str, limiet: int = 100, venster: int = 60) -> bool:
        nu = time.time()
        self.verzoeken[ip] = [t for t in self.verzoeken[ip] if nu - t < venster]
        self.verzoeken[ip].append(nu)

        if len(self.verzoeken[ip]) > limiet:
            self.geblokkeerd[ip] = nu + 300  # 5 minuten blokkeren
            return False
        return True

rate_limiter = RateLimiter()

class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        ip = request.client.host if request.client else "onbekend"

        if rate_limiter.is_geblokkeerd(ip):
            return JSONResponse(
                status_code=429,
                content={"detail": "Te veel verzoeken. Probeer later opnieuw."}
            )

        # Striktere limiet voor auth endpoints
        limiet = 10 if "/auth/" in request.url.path else 100
        if not rate_limiter.registreer_verzoek(ip, limiet=limiet):
            return JSONResponse(
                status_code=429,
                content={"detail": "Te veel verzoeken. Probeer later opnieuw."}
            )

        return await call_next(request)

# ============================================
# SECURITY HEADERS MIDDLEWARE
# ============================================

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)

        # Beveiligingsheaders toevoegen
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self' data:;"
        )

        # Server header verbergen
        if "server" in response.headers:
            del response.headers["server"]

        return response

# ============================================
# INPUT VALIDATIE MIDDLEWARE
# ============================================

class InputValidatieMiddleware(BaseHTTPMiddleware):
    VEILIGE_METHODEN = {"GET", "HEAD", "OPTIONS"}
    MAX_BODY_SIZE = 10 * 1024 * 1024  # 10MB

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Alleen POST/PUT/PATCH valideren
        if request.method in self.VEILIGE_METHODEN:
            return await call_next(request)

        # Content type controleren
        content_type = request.headers.get("content-type", "")

        if "application/json" in content_type:
            try:
                body = await request.body()

                # Grootte check
                if len(body) > self.MAX_BODY_SIZE:
                    return JSONResponse(
                        status_code=413,
                        content={"detail": "Verzoek te groot"}
                    )

                # Basis SQL injectie check op raw body
                body_tekst = body.decode("utf-8", errors="ignore")
                if bevat_sql_injectie(body_tekst) or bevat_xss(body_tekst):
                    return JSONResponse(
                        status_code=400,
                        content={"detail": "Ongeldige invoer gedetecteerd"}
                    )

            except Exception:
                pass

        return await call_next(request)

# ============================================
# LOGGING MIDDLEWARE
# ============================================

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        start_tijd = time.time()

        # Request info
        ip = request.client.host if request.client else "onbekend"
        methode = request.method
        pad = request.url.path

        response = await call_next(request)

        duur = round((time.time() - start_tijd) * 1000, 2)
        status = response.status_code

        # Log gevaarlijke status codes
        if status >= 400:
            print(f"⚠️  {methode} {pad} → {status} ({duur}ms) IP:{ip}")
        else:
            print(f"✓  {methode} {pad} → {status} ({duur}ms)")

        return response
