# ARC Booking Backend Template

## Wat zit erin
- PostgreSQL database met volledige booking structuur
- FastAPI backend met alle routes
- Agenda en beschikbaarheidsbeheer
- Automatische herinneringen via email en SMS
- Mollie + Stripe betaalintegratie
- Wachtlijst systeem
- Docker deployment ready
- Agent integratie (optioneel)

## API Endpoints

| Module | Basis URL |
|--------|-----------|
| Authenticatie | /api/v1/auth |
| Diensten | /api/v1/diensten |
| Medewerkers | /api/v1/medewerkers |
| Beschikbaarheid | /api/v1/beschikbaarheid |
| Reserveringen | /api/v1/reserveringen |
| Betalingen | /api/v1/betalingen |
| Wachtlijst | /api/v1/wachtlijst |
| Admin | /api/v1/admin |

## Compatibel met
Frontend: booking-v1, v2, v3, v4
Admin: admin-booking
Agent: agent-booking
