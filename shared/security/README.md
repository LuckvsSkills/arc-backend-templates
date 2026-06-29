# ARC Security Module

Gedeelde beveiligingslaag voor alle 6 backend templates.

## Wat is gedekt

### SQL Injectie
- Parameterized queries via SQLAlchemy (standaard)
- Pattern matching op gevaarlijke SQL commando's
- Input sanitatie voor alle POST/PUT/PATCH verzoeken

### XSS (Cross-Site Scripting)
- HTML escaping van alle tekst invoer
- Script tag detectie en verwijdering
- Gevaarlijke event handlers blokkeren

### Prompt Injectie (AI agents)
- 30+ patronen voor injectie pogingen
- Veilige prompt wrapper voor agent communicatie
- Systeem instructies kunnen niet overschreven worden
- Data exfiltratie pogingen worden geblokkeerd

### Rate Limiting
- 100 verzoeken per minuut per IP (algemeen)
- 10 verzoeken per minuut per IP (auth endpoints)
- 5 minuten blokkering bij overschrijding

### Security Headers
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- Strict-Transport-Security (HTTPS enforcing)
- Content-Security-Policy
- Server header verborgen

### Authenticatie
- bcrypt wachtwoord hashing
- JWT tokens met vervaldatum
- Wachtwoord sterkte validatie
- API sleutel hashing (SHA-256)
- Rol-gebaseerde toegang (RBAC)

## Gebruik in backend

```python
from shared.security import (
    saniteer_tekst,
    valideer_veiligheid,
    prompt_guard,
    RateLimitMiddleware,
    SecurityHeadersMiddleware,
    vereist_auth,
    vereist_admin
)

# Input saniteren
schone_input = saniteer_tekst(gebruiker_input)

# Veiligheid valideren
veilig, reden = valideer_veiligheid(gebruiker_input)

# Agent prompt bouwen
veilige_berichten = prompt_guard.bouw_veilige_prompt(
    systeem_instructie="Jij bent een shop assistent...",
    gebruiker_input=klant_bericht
)
```
