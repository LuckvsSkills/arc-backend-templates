-- ============================================
-- ARC BOOKING BACKEND TEMPLATE
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
    telefoon VARCHAR(20),
    rol VARCHAR(20) DEFAULT 'klant' CHECK (rol IN ('klant', 'medewerker', 'admin')),
    email_geverifieerd BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE,
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
-- LOCATIES & MEDEWERKERS
-- ============================================

CREATE TABLE locaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    adres VARCHAR(255),
    postcode VARCHAR(10),
    stad VARCHAR(100),
    telefoon VARCHAR(20),
    email VARCHAR(255),
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE medewerkers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    locatie_id UUID REFERENCES locaties(id) ON DELETE SET NULL,
    voornaam VARCHAR(100) NOT NULL,
    achternaam VARCHAR(100) NOT NULL,
    bio TEXT,
    foto_url TEXT,
    kleur VARCHAR(7) DEFAULT '#6366f1',
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DIENSTEN
-- ============================================

CREATE TABLE categorieen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    beschrijving TEXT,
    kleur VARCHAR(7) DEFAULT '#6366f1',
    volgorde INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE diensten (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    beschrijving TEXT,
    korte_beschrijving TEXT,
    categorie_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    duur_minuten INTEGER NOT NULL DEFAULT 60,
    buffer_voor INTEGER DEFAULT 0,
    buffer_na INTEGER DEFAULT 0,
    prijs DECIMAL(10,2) NOT NULL DEFAULT 0,
    btw_percentage DECIMAL(5,2) DEFAULT 21,
    max_deelnemers INTEGER DEFAULT 1,
    online_betaling BOOLEAN DEFAULT TRUE,
    aanbetaling_percentage DECIMAL(5,2) DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    afbeelding_url TEXT,
    meta_titel VARCHAR(255),
    meta_beschrijving TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE dienst_medewerkers (
    dienst_id UUID REFERENCES diensten(id) ON DELETE CASCADE,
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE CASCADE,
    PRIMARY KEY (dienst_id, medewerker_id)
);

-- ============================================
-- BESCHIKBAARHEID
-- ============================================

CREATE TABLE beschikbaarheid (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE CASCADE,
    dag_van_week INTEGER CHECK (dag_van_week BETWEEN 0 AND 6),
    start_tijd TIME NOT NULL,
    eind_tijd TIME NOT NULL,
    actief BOOLEAN DEFAULT TRUE
);

CREATE TABLE beschikbaarheid_uitzonderingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE CASCADE,
    datum DATE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('vrij', 'extra', 'aangepast')),
    start_tijd TIME,
    eind_tijd TIME,
    reden TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE geblokkeerde_tijden (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE CASCADE,
    start_datetime TIMESTAMPTZ NOT NULL,
    eind_datetime TIMESTAMPTZ NOT NULL,
    reden TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RESERVERINGEN
-- ============================================

CREATE TABLE reserveringen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserveringsnummer VARCHAR(50) UNIQUE NOT NULL,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    dienst_id UUID REFERENCES diensten(id) ON DELETE SET NULL,
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE SET NULL,
    locatie_id UUID REFERENCES locaties(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'nieuw' CHECK (status IN (
        'nieuw', 'bevestigd', 'betaling_wacht', 'betaald',
        'geannuleerd', 'niet_verschenen', 'voltooid'
    )),
    start_datetime TIMESTAMPTZ NOT NULL,
    eind_datetime TIMESTAMPTZ NOT NULL,
    klant_naam VARCHAR(255) NOT NULL,
    klant_email VARCHAR(255) NOT NULL,
    klant_telefoon VARCHAR(20),
    aantal_deelnemers INTEGER DEFAULT 1,
    prijs DECIMAL(10,2) NOT NULL DEFAULT 0,
    btw_bedrag DECIMAL(10,2) DEFAULT 0,
    totaal DECIMAL(10,2) NOT NULL DEFAULT 0,
    aanbetaling DECIMAL(10,2) DEFAULT 0,
    notities TEXT,
    intern_notities TEXT,
    herinnering_verstuurd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reservering_statussen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservering_id UUID REFERENCES reserveringen(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL,
    opmerking TEXT,
    aangemaakt_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BETALINGEN
-- ============================================

CREATE TABLE betalingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservering_id UUID REFERENCES reserveringen(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) UNIQUE,
    methode VARCHAR(50),
    status VARCHAR(30) DEFAULT 'wacht' CHECK (status IN (
        'wacht', 'geslaagd', 'mislukt', 'terugbetaald'
    )),
    bedrag DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    metadata JSONB,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- HERINNERINGEN & NOTIFICATIES
-- ============================================

CREATE TABLE notificatie_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(100) NOT NULL,
    type VARCHAR(30) CHECK (type IN ('email', 'sms', 'whatsapp')),
    trigger_event VARCHAR(50) CHECK (trigger_event IN (
        'reservering_bevestigd', 'reservering_geannuleerd',
        'herinnering_24u', 'herinnering_1u', 'follow_up'
    )),
    onderwerp VARCHAR(255),
    inhoud TEXT NOT NULL,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE verstuurde_notificaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservering_id UUID REFERENCES reserveringen(id) ON DELETE CASCADE,
    template_id UUID REFERENCES notificatie_templates(id),
    type VARCHAR(30),
    ontvanger VARCHAR(255),
    status VARCHAR(20) DEFAULT 'wacht',
    verstuurd_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- REVIEWS
-- ============================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservering_id UUID REFERENCES reserveringen(id) ON DELETE CASCADE,
    dienst_id UUID REFERENCES diensten(id) ON DELETE CASCADE,
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE SET NULL,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    naam VARCHAR(255),
    score INTEGER CHECK (score BETWEEN 1 AND 5),
    inhoud TEXT,
    goedgekeurd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WACHTLIJST
-- ============================================

CREATE TABLE wachtlijst (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dienst_id UUID REFERENCES diensten(id) ON DELETE CASCADE,
    medewerker_id UUID REFERENCES medewerkers(id) ON DELETE SET NULL,
    gewenste_datum DATE,
    klant_naam VARCHAR(255) NOT NULL,
    klant_email VARCHAR(255) NOT NULL,
    klant_telefoon VARCHAR(20),
    status VARCHAR(20) DEFAULT 'wacht' CHECK (status IN ('wacht', 'aangeboden', 'geboekt', 'verlopen')),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WINKEL INSTELLINGEN
-- ============================================

CREATE TABLE instellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleutel VARCHAR(100) UNIQUE NOT NULL,
    waarde TEXT,
    type VARCHAR(20) DEFAULT 'tekst',
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO instellingen (sleutel, waarde, type) VALUES
('bedrijf_naam', '{{BEDRIJF_NAAM}}', 'tekst'),
('bedrijf_email', '{{BEDRIJF_EMAIL}}', 'tekst'),
('tijdzone', 'Europe/Amsterdam', 'tekst'),
('valuta', 'EUR', 'tekst'),
('btw_percentage', '21', 'getal'),
('annulering_uren', '24', 'getal'),
('herinnering_uren', '24', 'getal'),
('online_betaling', 'true', 'boolean'),
('wachtlijst_actief', 'true', 'boolean');

-- ============================================
-- INDEXEN
-- ============================================

CREATE INDEX idx_reserveringen_datum ON reserveringen(start_datetime);
CREATE INDEX idx_reserveringen_medewerker ON reserveringen(medewerker_id);
CREATE INDEX idx_reserveringen_status ON reserveringen(status);
CREATE INDEX idx_reserveringen_nummer ON reserveringen(reserveringsnummer);
CREATE INDEX idx_beschikbaarheid_medewerker ON beschikbaarheid(medewerker_id);
CREATE INDEX idx_gebruikers_email ON gebruikers(email);

-- ============================================
-- AUTOMATISCHE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN NEW.bijgewerkt_op = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gebruikers_bijgewerkt BEFORE UPDATE ON gebruikers FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_diensten_bijgewerkt BEFORE UPDATE ON diensten FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_reserveringen_bijgewerkt BEFORE UPDATE ON reserveringen FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

-- ============================================
-- RESERVERINGSNUMMER GENERATOR
-- ============================================

CREATE SEQUENCE reserveringsnummer_seq START 1000;

CREATE OR REPLACE FUNCTION genereer_reserveringsnummer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.reserveringsnummer = '{{BEDRIJF_PREFIX}}-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(nextval('reserveringsnummer_seq')::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_reserveringsnummer
    BEFORE INSERT ON reserveringen
    FOR EACH ROW EXECUTE FUNCTION genereer_reserveringsnummer();
