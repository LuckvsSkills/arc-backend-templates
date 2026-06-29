# ARC E-Commerce Backend Template

## Wat zit erin

- Volledige PostgreSQL database met alle tabellen
- FastAPI backend met alle routes
- JWT authenticatie
- Mollie + Stripe betaalintegratie
- S3 media opslag
- Docker deployment ready
- Agent integratie (optioneel)

## Forge deployment instructies

```bash
# 1. Kopieer template
cp -r ecommerce/ /klant/backend/

# 2. Vul variabelen in
cp .env.example .env
# Forge vult automatisch in vanuit forge.json

# 3. Start database
docker-compose up -d database

# 4. Initialiseer schema
docker-compose exec database psql -U gebruiker -d webshop_db -f /docker-entrypoint-initdb.d/schema.sql

# 5. Start API
docker-compose up -d api
```

## API Endpoints

| Module | Basis URL |
|--------|-----------|
| Authenticatie | /api/v1/auth |
| Producten | /api/v1/producten |
| Categorieën | /api/v1/categorieen |
| Bestellingen | /api/v1/bestellingen |
| Betalingen | /api/v1/betalingen |
| Winkelwagen | /api/v1/winkelwagen |
| Reviews | /api/v1/reviews |
| Admin | /api/v1/admin |

## Compatibel met

Frontend: ecommerce-v1, v2, v3, v4
Admin: admin-ecommerce
Agent: agent-ecommerce
