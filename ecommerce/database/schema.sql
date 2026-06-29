-- ============================================
-- ARC E-COMMERCE BACKEND TEMPLATE
-- Database: PostgreSQL
-- Versie: 1.0
-- ============================================

-- EXTENSIES
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
    rol VARCHAR(20) DEFAULT 'klant' CHECK (rol IN ('klant', 'admin', 'medewerker')),
    email_geverifieerd BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE,
    laatste_login TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE adressen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'bezorg' CHECK (type IN ('bezorg', 'factuur')),
    straat VARCHAR(255) NOT NULL,
    huisnummer VARCHAR(20) NOT NULL,
    toevoeging VARCHAR(20),
    postcode VARCHAR(10) NOT NULL,
    stad VARCHAR(100) NOT NULL,
    provincie VARCHAR(100),
    land VARCHAR(100) DEFAULT 'Nederland',
    is_standaard BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sessies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    verloopt_op TIMESTAMPTZ NOT NULL,
    ip_adres INET,
    user_agent TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WINKEL CONFIGURATIE
-- ============================================

CREATE TABLE winkel_instellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleutel VARCHAR(100) UNIQUE NOT NULL,
    waarde TEXT,
    type VARCHAR(20) DEFAULT 'tekst' CHECK (type IN ('tekst', 'getal', 'boolean', 'json')),
    beschrijving TEXT,
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- Standaard instellingen
INSERT INTO winkel_instellingen (sleutel, waarde, type, beschrijving) VALUES
('winkel_naam', '{{WINKEL_NAAM}}', 'tekst', 'Naam van de webshop'),
('winkel_email', '{{WINKEL_EMAIL}}', 'tekst', 'Contact email'),
('valuta', 'EUR', 'tekst', 'Valuta code'),
('btw_percentage', '21', 'getal', 'Standaard BTW percentage'),
('gratis_verzending_vanaf', '50', 'getal', 'Gratis verzending vanaf bedrag'),
('verzendkosten', '4.95', 'getal', 'Standaard verzendkosten'),
('max_producten_per_pagina', '24', 'getal', 'Producten per pagina'),
('bestellingen_email_actief', 'true', 'boolean', 'Email bij nieuwe bestelling');

-- ============================================
-- PRODUCTEN
-- ============================================

CREATE TABLE categorieen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    beschrijving TEXT,
    afbeelding_url TEXT,
    parent_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    volgorde INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    meta_titel VARCHAR(255),
    meta_beschrijving TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE merken (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    logo_url TEXT,
    website_url TEXT,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE producten (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    sku VARCHAR(100) UNIQUE,
    beschrijving TEXT,
    korte_beschrijving TEXT,
    categorie_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    merk_id UUID REFERENCES merken(id) ON DELETE SET NULL,
    prijs DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_prijs DECIMAL(10,2),
    inkoopprijs DECIMAL(10,2),
    btw_percentage DECIMAL(5,2) DEFAULT 21,
    voorraad INTEGER DEFAULT 0,
    min_voorraad INTEGER DEFAULT 0,
    voorraad_bijhouden BOOLEAN DEFAULT TRUE,
    gewicht DECIMAL(8,2),
    lengte DECIMAL(8,2),
    breedte DECIMAL(8,2),
    hoogte DECIMAL(8,2),
    digitaal BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE,
    uitgelicht BOOLEAN DEFAULT FALSE,
    nieuw BOOLEAN DEFAULT FALSE,
    meta_titel VARCHAR(255),
    meta_beschrijving TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_afbeeldingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES producten(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    alt_tekst VARCHAR(255),
    volgorde INTEGER DEFAULT 0,
    is_hoofd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_varianten (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES producten(id) ON DELETE CASCADE,
    naam VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    prijs DECIMAL(10,2),
    sale_prijs DECIMAL(10,2),
    voorraad INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE variant_opties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    variant_id UUID REFERENCES product_varianten(id) ON DELETE CASCADE,
    naam VARCHAR(100) NOT NULL,
    waarde VARCHAR(255) NOT NULL
);

CREATE TABLE product_tags (
    product_id UUID REFERENCES producten(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    PRIMARY KEY (product_id, tag)
);

-- ============================================
-- BESTELLINGEN
-- ============================================

CREATE TABLE bestellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bestelnummer VARCHAR(50) UNIQUE NOT NULL,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'nieuw' CHECK (status IN (
        'nieuw', 'betaling_wacht', 'betaald', 'verwerking',
        'verzonden', 'geleverd', 'geannuleerd', 'terugbetaald'
    )),
    subtotaal DECIMAL(10,2) NOT NULL DEFAULT 0,
    btw_bedrag DECIMAL(10,2) NOT NULL DEFAULT 0,
    verzendkosten DECIMAL(10,2) NOT NULL DEFAULT 0,
    korting DECIMAL(10,2) NOT NULL DEFAULT 0,
    totaal DECIMAL(10,2) NOT NULL DEFAULT 0,
    valuta VARCHAR(3) DEFAULT 'EUR',
    bezorg_naam VARCHAR(255),
    bezorg_straat VARCHAR(255),
    bezorg_huisnummer VARCHAR(20),
    bezorg_postcode VARCHAR(10),
    bezorg_stad VARCHAR(100),
    bezorg_land VARCHAR(100) DEFAULT 'Nederland',
    factuur_naam VARCHAR(255),
    factuur_straat VARCHAR(255),
    factuur_huisnummer VARCHAR(20),
    factuur_postcode VARCHAR(10),
    factuur_stad VARCHAR(100),
    factuur_land VARCHAR(100),
    klant_email VARCHAR(255),
    klant_telefoon VARCHAR(20),
    notities TEXT,
    intern_notities TEXT,
    kortingscode VARCHAR(50),
    betaalmethode VARCHAR(50),
    betaling_id VARCHAR(255),
    track_trace VARCHAR(255),
    verzendmethode VARCHAR(100),
    verzonden_op TIMESTAMPTZ,
    geleverd_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bestelling_regels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bestelling_id UUID REFERENCES bestellingen(id) ON DELETE CASCADE,
    product_id UUID REFERENCES producten(id) ON DELETE SET NULL,
    variant_id UUID REFERENCES product_varianten(id) ON DELETE SET NULL,
    naam VARCHAR(500) NOT NULL,
    sku VARCHAR(100),
    aantal INTEGER NOT NULL DEFAULT 1,
    stukprijs DECIMAL(10,2) NOT NULL,
    btw_percentage DECIMAL(5,2) DEFAULT 21,
    totaal DECIMAL(10,2) NOT NULL,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bestelling_statussen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bestelling_id UUID REFERENCES bestellingen(id) ON DELETE CASCADE,
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
    bestelling_id UUID REFERENCES bestellingen(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) UNIQUE,
    methode VARCHAR(50),
    status VARCHAR(30) DEFAULT 'wacht' CHECK (status IN (
        'wacht', 'geslaagd', 'mislukt', 'terugbetaald', 'gedeeltelijk_terugbetaald'
    )),
    bedrag DECIMAL(10,2) NOT NULL,
    valuta VARCHAR(3) DEFAULT 'EUR',
    terugbetaald_bedrag DECIMAL(10,2) DEFAULT 0,
    metadata JSONB,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- KORTINGSCODES
-- ============================================

CREATE TABLE kortingscodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('percentage', 'vast_bedrag', 'gratis_verzending')),
    waarde DECIMAL(10,2),
    min_bestelbedrag DECIMAL(10,2),
    max_gebruik INTEGER,
    gebruik_teller INTEGER DEFAULT 0,
    per_gebruiker INTEGER DEFAULT 1,
    geldig_van TIMESTAMPTZ,
    geldig_tot TIMESTAMPTZ,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- WINKELWAGEN
-- ============================================

CREATE TABLE winkelwagens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    sessie_token VARCHAR(255),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE winkelwagen_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    winkelwagen_id UUID REFERENCES winkelwagens(id) ON DELETE CASCADE,
    product_id UUID REFERENCES producten(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_varianten(id) ON DELETE SET NULL,
    aantal INTEGER NOT NULL DEFAULT 1,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- REVIEWS
-- ============================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES producten(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    naam VARCHAR(255),
    email VARCHAR(255),
    score INTEGER CHECK (score BETWEEN 1 AND 5),
    titel VARCHAR(255),
    inhoud TEXT,
    geverifieerde_aankoop BOOLEAN DEFAULT FALSE,
    goedgekeurd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- NIEUWSBRIEF
-- ============================================

CREATE TABLE nieuwsbrief (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    naam VARCHAR(255),
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MEDIA BIBLIOTHEEK
-- ============================================

CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bestandsnaam VARCHAR(255) NOT NULL,
    originele_naam VARCHAR(255),
    url TEXT NOT NULL,
    type VARCHAR(50),
    grootte INTEGER,
    breedte INTEGER,
    hoogte INTEGER,
    alt_tekst VARCHAR(255),
    geupload_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXEN VOOR PERFORMANCE
-- ============================================

CREATE INDEX idx_producten_slug ON producten(slug);
CREATE INDEX idx_producten_categorie ON producten(categorie_id);
CREATE INDEX idx_producten_actief ON producten(actief);
CREATE INDEX idx_producten_zoek ON producten USING gin(naam gin_trgm_ops);
CREATE INDEX idx_bestellingen_gebruiker ON bestellingen(gebruiker_id);
CREATE INDEX idx_bestellingen_status ON bestellingen(status);
CREATE INDEX idx_bestellingen_nummer ON bestellingen(bestelnummer);
CREATE INDEX idx_gebruikers_email ON gebruikers(email);
CREATE INDEX idx_sessies_token ON sessies(token);

-- ============================================
-- AUTOMATISCHE TIMESTAMP UPDATE
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN
    NEW.bijgewerkt_op = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gebruikers_bijgewerkt
    BEFORE UPDATE ON gebruikers
    FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

CREATE TRIGGER tr_producten_bijgewerkt
    BEFORE UPDATE ON producten
    FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

CREATE TRIGGER tr_bestellingen_bijgewerkt
    BEFORE UPDATE ON bestellingen
    FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

-- ============================================
-- BESTELNUMMER GENERATOR
-- ============================================

CREATE SEQUENCE bestelnummer_seq START 1000;

CREATE OR REPLACE FUNCTION genereer_bestelnummer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.bestelnummer = '{{WINKEL_PREFIX}}-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('bestelnummer_seq')::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_bestelnummer
    BEFORE INSERT ON bestellingen
    FOR EACH ROW EXECUTE FUNCTION genereer_bestelnummer();
