-- ============================================
-- ARC SAAS BACKEND TEMPLATE
-- Database: PostgreSQL
-- Versie: 1.0
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- GEBRUIKERS & AUTHENTICATIE
-- ============================================

CREATE TABLE gebruikers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    wachtwoord_hash VARCHAR(255) NOT NULL,
    voornaam VARCHAR(100),
    achternaam VARCHAR(100),
    avatar_url TEXT,
    tijdzone VARCHAR(50) DEFAULT 'Europe/Amsterdam',
    taal VARCHAR(10) DEFAULT 'nl',
    email_geverifieerd BOOLEAN DEFAULT FALSE,
    twee_factor_actief BOOLEAN DEFAULT FALSE,
    twee_factor_secret VARCHAR(255),
    actief BOOLEAN DEFAULT TRUE,
    laatste_login TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sessies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    apparaat VARCHAR(255),
    ip_adres INET,
    verloopt_op TIMESTAMPTZ NOT NULL,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE wachtwoord_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    verloopt_op TIMESTAMPTZ NOT NULL,
    gebruikt BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ORGANISATIES & WORKSPACES
-- ============================================

CREATE TABLE organisaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    logo_url TEXT,
    website VARCHAR(255),
    kvk_nummer VARCHAR(20),
    btw_nummer VARCHAR(20),
    factuur_email VARCHAR(255),
    factuur_naam VARCHAR(255),
    factuur_adres TEXT,
    plan VARCHAR(50) DEFAULT 'gratis' CHECK (plan IN (
        'gratis', 'starter', 'pro', 'enterprise'
    )),
    plan_verloopt_op TIMESTAMPTZ,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE organisatie_leden (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    rol VARCHAR(30) DEFAULT 'lid' CHECK (rol IN ('eigenaar', 'admin', 'lid', 'gast')),
    uitgenodigd_door UUID REFERENCES gebruikers(id),
    uitnodiging_email VARCHAR(255),
    uitnodiging_token VARCHAR(255),
    status VARCHAR(20) DEFAULT 'actief' CHECK (status IN ('uitgenodigd', 'actief', 'inactief')),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organisatie_id, gebruiker_id)
);

-- ============================================
-- ABONNEMENTEN & FACTURATIE
-- ============================================

CREATE TABLE abonnement_plannen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    beschrijving TEXT,
    prijs_maand DECIMAL(10,2) NOT NULL DEFAULT 0,
    prijs_jaar DECIMAL(10,2),
    valuta VARCHAR(3) DEFAULT 'EUR',
    max_gebruikers INTEGER,
    max_projecten INTEGER,
    max_opslag_gb INTEGER,
    api_toegang BOOLEAN DEFAULT FALSE,
    prioriteit_support BOOLEAN DEFAULT FALSE,
    functies JSONB DEFAULT '[]',
    actief BOOLEAN DEFAULT TRUE,
    volgorde INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO abonnement_plannen (naam, slug, prijs_maand, prijs_jaar, max_gebruikers, max_projecten, max_opslag_gb, functies) VALUES
('Gratis', 'gratis', 0, 0, 3, 3, 1, '["Basis functies", "Community support"]'),
('Starter', 'starter', {{PRIJS_STARTER}}, {{PRIJS_STARTER_JAAR}}, 10, 10, 10, '["Alle basis functies", "Email support", "API toegang"]'),
('Pro', 'pro', {{PRIJS_PRO}}, {{PRIJS_PRO_JAAR}}, 50, 50, 100, '["Alle starter functies", "Prioriteit support", "Geavanceerde analytics"]'),
('Enterprise', 'enterprise', {{PRIJS_ENTERPRISE}}, {{PRIJS_ENTERPRISE_JAAR}}, NULL, NULL, NULL, '["Alles", "Dedicated support", "SLA garantie", "Custom integraties"]');

CREATE TABLE abonnementen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES abonnement_plannen(id),
    status VARCHAR(30) DEFAULT 'actief' CHECK (status IN (
        'actief', 'gepauzeerd', 'geannuleerd', 'verlopen', 'proefperiode'
    )),
    periode VARCHAR(20) DEFAULT 'maand' CHECK (periode IN ('maand', 'jaar')),
    prijs DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    huidige_periode_start TIMESTAMPTZ,
    huidige_periode_eind TIMESTAMPTZ,
    proefperiode_eind TIMESTAMPTZ,
    geannuleerd_op TIMESTAMPTZ,
    provider VARCHAR(50),
    provider_id VARCHAR(255),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE facturen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    abonnement_id UUID REFERENCES abonnementen(id),
    factuurnummer VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'concept' CHECK (status IN (
        'concept', 'verzonden', 'betaald', 'achterstallig', 'geannuleerd'
    )),
    subtotaal DECIMAL(10,2) NOT NULL,
    btw_percentage DECIMAL(5,2) DEFAULT 21,
    btw_bedrag DECIMAL(10,2) NOT NULL,
    totaal DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    vervaldatum DATE,
    betaald_op TIMESTAMPTZ,
    betaalmethode VARCHAR(50),
    provider_id VARCHAR(255),
    pdf_url TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE betalingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    factuur_id UUID REFERENCES facturen(id) ON DELETE CASCADE,
    organisatie_id UUID REFERENCES organisaties(id),
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) UNIQUE,
    methode VARCHAR(50),
    status VARCHAR(30) DEFAULT 'wacht',
    bedrag DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    metadata JSONB,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- API SLEUTELS
-- ============================================

CREATE TABLE api_sleutels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    aangemaakt_door UUID REFERENCES gebruikers(id),
    naam VARCHAR(255) NOT NULL,
    sleutel_hash VARCHAR(255) UNIQUE NOT NULL,
    sleutel_prefix VARCHAR(20) NOT NULL,
    rechten JSONB DEFAULT '["lezen"]',
    laatste_gebruik TIMESTAMPTZ,
    verzoeken_teller INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    verloopt_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- GEBRUIK & LIMIETEN
-- ============================================

CREATE TABLE gebruik_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    api_sleutel_id UUID REFERENCES api_sleutels(id) ON DELETE SET NULL,
    eindpunt VARCHAR(255),
    methode VARCHAR(10),
    status_code INTEGER,
    responstijd_ms INTEGER,
    ip_adres INET,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gebruik_statistieken (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    periode DATE NOT NULL,
    api_verzoeken INTEGER DEFAULT 0,
    actieve_gebruikers INTEGER DEFAULT 0,
    opslag_gebrukt_mb INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organisatie_id, periode)
);

-- ============================================
-- WEBHOOKS
-- ============================================

CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organisatie_id UUID REFERENCES organisaties(id) ON DELETE CASCADE,
    naam VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    events JSONB DEFAULT '[]',
    geheim VARCHAR(255),
    actief BOOLEAN DEFAULT TRUE,
    laatste_activering TIMESTAMPTZ,
    fout_teller INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID REFERENCES webhooks(id) ON DELETE CASCADE,
    event VARCHAR(100),
    payload JSONB,
    status_code INTEGER,
    respons TEXT,
    geslaagd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIES
-- ============================================

CREATE TABLE notificaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(50),
    titel VARCHAR(255),
    inhoud TEXT,
    actie_url TEXT,
    gelezen BOOLEAN DEFAULT FALSE,
    gelezen_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PLATFORM INSTELLINGEN
-- ============================================

CREATE TABLE instellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleutel VARCHAR(100) UNIQUE NOT NULL,
    waarde TEXT,
    type VARCHAR(20) DEFAULT 'tekst',
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO instellingen (sleutel, waarde, type) VALUES
('platform_naam', '{{PLATFORM_NAAM}}', 'tekst'),
('platform_url', '{{PLATFORM_URL}}', 'tekst'),
('platform_email', '{{PLATFORM_EMAIL}}', 'tekst'),
('proefperiode_dagen', '14', 'getal'),
('api_rate_limit', '1000', 'getal'),
('registratie_open', 'true', 'boolean'),
('email_verificatie_verplicht', 'true', 'boolean');

-- ============================================
-- INDEXEN
-- ============================================

CREATE INDEX idx_gebruikers_email ON gebruikers(email);
CREATE INDEX idx_organisaties_slug ON organisaties(slug);
CREATE INDEX idx_org_leden_org ON organisatie_leden(organisatie_id);
CREATE INDEX idx_org_leden_gebruiker ON organisatie_leden(gebruiker_id);
CREATE INDEX idx_abonnementen_org ON abonnementen(organisatie_id);
CREATE INDEX idx_api_sleutels_prefix ON api_sleutels(sleutel_prefix);
CREATE INDEX idx_gebruik_logs_org ON gebruik_logs(organisatie_id);
CREATE INDEX idx_gebruik_logs_datum ON gebruik_logs(aangemaakt_op);
CREATE INDEX idx_notificaties_gebruiker ON notificaties(gebruiker_id, gelezen);

-- ============================================
-- AUTOMATISCHE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN NEW.bijgewerkt_op = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gebruikers_bijgewerkt BEFORE UPDATE ON gebruikers FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_organisaties_bijgewerkt BEFORE UPDATE ON organisaties FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_abonnementen_bijgewerkt BEFORE UPDATE ON abonnementen FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

-- ============================================
-- FACTUURNUMMER GENERATOR
-- ============================================

CREATE SEQUENCE factuurnummer_seq START 1000;

CREATE OR REPLACE FUNCTION genereer_factuurnummer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.factuurnummer = '{{PLATFORM_PREFIX}}-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('factuurnummer_seq')::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_factuurnummer
    BEFORE INSERT ON facturen
    FOR EACH ROW EXECUTE FUNCTION genereer_factuurnummer();
