# ARC SaaS Backend Template

## Wat zit erin
- Multi-tenant architectuur met organisaties
- Abonnementsbeheer met proefperiode
- Automatische facturatie en betalingen
- API sleutelbeheer met rate limiting
- Webhook systeem
- Gebruik analytics
- Twee-factor authenticatie
- Docker deployment ready

## API Endpoints

| Module | Basis URL |
|--------|-----------|
| Authenticatie | /api/v1/auth |
| Organisaties | /api/v1/organisaties |
| Abonnementen | /api/v1/abonnementen |
| Facturen | /api/v1/facturen |
| API Sleutels | /api/v1/api-sleutels |
| Webhooks | /api/v1/webhooks |
| Gebruik | /api/v1/gebruik |
| Admin | /api/v1/admin |

## Compatibel met
Frontend: saas-v1/2/3/4, landing-v1/2/3/4
Admin: admin-saas
Agent: agent-saas
