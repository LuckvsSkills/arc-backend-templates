-- ============================================
-- ARC MARKETPLACE BACKEND TEMPLATE
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
    telefoon VARCHAR(20),
    rol VARCHAR(20) DEFAULT 'koper' CHECK (rol IN ('koper', 'verkoper', 'beide', 'admin', 'moderator')),
    email_geverifieerd BOOLEAN DEFAULT FALSE,
    identiteit_geverifieerd BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE,
    geblokkeerd BOOLEAN DEFAULT FALSE,
    blokkeringreden TEXT,
    laatste_login TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sessies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    verloopt_op TIMESTAMPTZ NOT NULL,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VERKOPER PROFIELEN
-- ============================================

CREATE TABLE verkoper_profielen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE UNIQUE,
    bedrijfsnaam VARCHAR(255),
    beschrijving TEXT,
    logo_url TEXT,
    banner_url TEXT,
    website_url TEXT,
    kvk_nummer VARCHAR(20),
    btw_nummer VARCHAR(20),
    iban VARCHAR(34),
    rekeninghouder VARCHAR(255),
    adres VARCHAR(255),
    postcode VARCHAR(10),
    stad VARCHAR(100),
    land VARCHAR(100) DEFAULT 'Nederland',
    commissie_percentage DECIMAL(5,2) DEFAULT 10.00,
    uitbetaling_drempel DECIMAL(10,2) DEFAULT 50.00,
    status VARCHAR(20) DEFAULT 'aangevraagd' CHECK (status IN (
        'aangevraagd', 'actief', 'geschorst', 'geweigerd'
    )),
    goedgekeurd_op TIMESTAMPTZ,
    goedgekeurd_door UUID REFERENCES gebruikers(id),
    gem_beoordeling DECIMAL(3,2) DEFAULT 0,
    totaal_beoordelingen INTEGER DEFAULT 0,
    totaal_verkopen INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CATEGORIEËN
-- ============================================

CREATE TABLE categorieen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    beschrijving TEXT,
    afbeelding_url TEXT,
    icoon VARCHAR(50),
    parent_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    volgorde INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ADVERTENTIES & PRODUCTEN
-- ============================================

CREATE TABLE advertenties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verkoper_id UUID REFERENCES verkoper_profielen(id) ON DELETE CASCADE,
    categorie_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    titel VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    beschrijving TEXT,
    prijs DECIMAL(10,2),
    prijs_type VARCHAR(20) DEFAULT 'vast' CHECK (prijs_type IN (
        'vast', 'onderhandelbaar', 'op_aanvraag', 'gratis'
    )),
    conditie VARCHAR(20) DEFAULT 'nieuw' CHECK (conditie IN (
        'nieuw', 'als_nieuw', 'goed', 'redelijk', 'slecht'
    )),
    voorraad INTEGER DEFAULT 1,
    locatie VARCHAR(255),
    stad VARCHAR(100),
    provincie VARCHAR(100),
    land VARCHAR(100) DEFAULT 'Nederland',
    levering BOOLEAN DEFAULT FALSE,
    ophalen BOOLEAN DEFAULT TRUE,
    verzendkosten DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'concept' CHECK (status IN (
        'concept', 'actief', 'verkocht', 'gereserveerd',
        'verlopen', 'verwijderd', 'geblokkeerd'
    )),
    uitgelicht BOOLEAN DEFAULT FALSE,
    weergaven INTEGER DEFAULT 0,
    favorieten_count INTEGER DEFAULT 0,
    verloopt_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE advertentie_afbeeldingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    alt_tekst VARCHAR(255),
    volgorde INTEGER DEFAULT 0,
    is_hoofd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE advertentie_attributen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE CASCADE,
    naam VARCHAR(100) NOT NULL,
    waarde VARCHAR(255) NOT NULL
);

CREATE TABLE favorieten (
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE CASCADE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (gebruiker_id, advertentie_id)
);

-- ============================================
-- TRANSACTIES & BETALINGEN
-- ============================================

CREATE TABLE transacties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transactienummer VARCHAR(50) UNIQUE NOT NULL,
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE SET NULL,
    koper_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    verkoper_id UUID REFERENCES verkoper_profielen(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'aangevraagd' CHECK (status IN (
        'aangevraagd', 'geaccepteerd', 'betaling_wacht', 'betaald',
        'verzonden', 'geleverd', 'voltooid', 'geannuleerd',
        'terugbetaald', 'geschil'
    )),
    bedrag DECIMAL(10,2) NOT NULL,
    commissie_percentage DECIMAL(5,2) NOT NULL,
    commissie_bedrag DECIMAL(10,2) NOT NULL,
    verkoper_bedrag DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    levering_methode VARCHAR(30) CHECK (levering_methode IN ('ophalen', 'verzending', 'digitaal')),
    bezorg_adres TEXT,
    track_trace VARCHAR(255),
    notities TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE betalingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transactie_id UUID REFERENCES transacties(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) UNIQUE,
    methode VARCHAR(50),
    status VARCHAR(30) DEFAULT 'wacht',
    bedrag DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    metadata JSONB,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE uitbetalingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verkoper_id UUID REFERENCES verkoper_profielen(id) ON DELETE CASCADE,
    bedrag DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'aangevraagd' CHECK (status IN (
        'aangevraagd', 'verwerking', 'uitbetaald', 'mislukt'
    )),
    referentie VARCHAR(255),
    uitbetaald_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BERICHTEN
-- ============================================

CREATE TABLE gesprekken (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE SET NULL,
    transactie_id UUID REFERENCES transacties(id) ON DELETE SET NULL,
    deelnemer_1 UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    deelnemer_2 UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    laatste_bericht_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE berichten (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gesprek_id UUID REFERENCES gesprekken(id) ON DELETE CASCADE,
    verzender_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    inhoud TEXT NOT NULL,
    bijlage_url TEXT,
    gelezen BOOLEAN DEFAULT FALSE,
    gelezen_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- REVIEWS & BEOORDELINGEN
-- ============================================

CREATE TABLE beoordelingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transactie_id UUID REFERENCES transacties(id) ON DELETE CASCADE,
    beoordelaar_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    beoordeelde_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(10) CHECK (type IN ('koper', 'verkoper')),
    score INTEGER CHECK (score BETWEEN 1 AND 5),
    inhoud TEXT,
    goedgekeurd BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MODERATIE & MELDINGEN
-- ============================================

CREATE TABLE meldingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    melder_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    type VARCHAR(30) CHECK (type IN ('advertentie', 'gebruiker', 'bericht')),
    advertentie_id UUID REFERENCES advertenties(id) ON DELETE SET NULL,
    gemelde_gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    reden VARCHAR(50) CHECK (reden IN (
        'spam', 'fraude', 'verboden_product', 'misleidend',
        'ongepaste_inhoud', 'anders'
    )),
    beschrijving TEXT,
    status VARCHAR(20) DEFAULT 'nieuw' CHECK (status IN ('nieuw', 'in_behandeling', 'opgelost', 'afgewezen')),
    behandeld_door UUID REFERENCES gebruikers(id),
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
('platform_email', '{{PLATFORM_EMAIL}}', 'tekst'),
('platform_url', '{{PLATFORM_URL}}', 'tekst'),
('standaard_commissie', '10', 'getal'),
('max_afbeeldingen', '10', 'getal'),
('advertentie_looptijd_dagen', '30', 'getal'),
('gratis_advertenties', 'true', 'boolean'),
('verificatie_verplicht', 'false', 'boolean');

-- ============================================
-- INDEXEN
-- ============================================

CREATE INDEX idx_advertenties_slug ON advertenties(slug);
CREATE INDEX idx_advertenties_status ON advertenties(status);
CREATE INDEX idx_advertenties_categorie ON advertenties(categorie_id);
CREATE INDEX idx_advertenties_verkoper ON advertenties(verkoper_id);
CREATE INDEX idx_advertenties_zoek ON advertenties USING gin(titel gin_trgm_ops);
CREATE INDEX idx_transacties_koper ON transacties(koper_id);
CREATE INDEX idx_transacties_verkoper ON transacties(verkoper_id);
CREATE INDEX idx_berichten_gesprek ON berichten(gesprek_id);
CREATE INDEX idx_gebruikers_email ON gebruikers(email);

-- ============================================
-- AUTOMATISCHE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN NEW.bijgewerkt_op = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gebruikers_bijgewerkt BEFORE UPDATE ON gebruikers FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_advertenties_bijgewerkt BEFORE UPDATE ON advertenties FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_transacties_bijgewerkt BEFORE UPDATE ON transacties FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

-- ============================================
-- TRANSACTIENUMMER GENERATOR
-- ============================================

CREATE SEQUENCE transactienummer_seq START 10000;

CREATE OR REPLACE FUNCTION genereer_transactienummer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.transactienummer = '{{PLATFORM_PREFIX}}-TRX-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('transactienummer_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_transactienummer
    BEFORE INSERT ON transacties
    FOR EACH ROW EXECUTE FUNCTION genereer_transactienummer();

-- AUTOMATISCH GEM BEOORDELING BIJWERKEN
CREATE OR REPLACE FUNCTION update_gem_beoordeling()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE verkoper_profielen
    SET gem_beoordeling = (
        SELECT COALESCE(AVG(score::DECIMAL), 0)
        FROM beoordelingen
        WHERE beoordeelde_id = NEW.beoordeelde_id AND type = 'verkoper'
    ),
    totaal_beoordelingen = (
        SELECT COUNT(*) FROM beoordelingen
        WHERE beoordeelde_id = NEW.beoordeelde_id AND type = 'verkoper'
    )
    WHERE gebruiker_id = NEW.beoordeelde_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gem_beoordeling
    AFTER INSERT ON beoordelingen
    FOR EACH ROW EXECUTE FUNCTION update_gem_beoordeling();
