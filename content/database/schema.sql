-- ============================================
-- ARC CONTENT BACKEND TEMPLATE
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
    bio TEXT,
    avatar_url TEXT,
    website_url TEXT,
    rol VARCHAR(20) DEFAULT 'lezer' CHECK (rol IN ('lezer', 'auteur', 'redacteur', 'admin')),
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
-- CATEGORIEËN & TAGS
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
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    beschrijving TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ARTIKELEN
-- ============================================

CREATE TABLE artikelen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titel VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    ondertitel VARCHAR(500),
    inhoud TEXT,
    samenvatting TEXT,
    auteur_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    categorie_id UUID REFERENCES categorieen(id) ON DELETE SET NULL,
    uitgelichte_afbeelding_url TEXT,
    uitgelichte_afbeelding_alt TEXT,
    status VARCHAR(20) DEFAULT 'concept' CHECK (status IN (
        'concept', 'review', 'gepland', 'gepubliceerd', 'gearchiveerd'
    )),
    gepubliceerd_op TIMESTAMPTZ,
    geplande_publicatie TIMESTAMPTZ,
    leestijd_minuten INTEGER,
    weergaven INTEGER DEFAULT 0,
    uitgelicht BOOLEAN DEFAULT FALSE,
    commentaar_toegestaan BOOLEAN DEFAULT TRUE,
    meta_titel VARCHAR(255),
    meta_beschrijving TEXT,
    meta_afbeelding_url TEXT,
    canonical_url TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE artikel_categorieen (
    artikel_id UUID REFERENCES artikelen(id) ON DELETE CASCADE,
    categorie_id UUID REFERENCES categorieen(id) ON DELETE CASCADE,
    PRIMARY KEY (artikel_id, categorie_id)
);

CREATE TABLE artikel_tags (
    artikel_id UUID REFERENCES artikelen(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (artikel_id, tag_id)
);

CREATE TABLE artikel_revisies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    artikel_id UUID REFERENCES artikelen(id) ON DELETE CASCADE,
    titel VARCHAR(500),
    inhoud TEXT,
    revisie_nummer INTEGER NOT NULL,
    aangemaakt_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PAGINA'S
-- ============================================

CREATE TABLE paginas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titel VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    inhoud TEXT,
    template VARCHAR(100) DEFAULT 'standaard',
    status VARCHAR(20) DEFAULT 'concept' CHECK (status IN (
        'concept', 'gepubliceerd', 'gearchiveerd'
    )),
    parent_id UUID REFERENCES paginas(id) ON DELETE SET NULL,
    volgorde INTEGER DEFAULT 0,
    in_navigatie BOOLEAN DEFAULT FALSE,
    meta_titel VARCHAR(255),
    meta_beschrijving TEXT,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MEDIA BIBLIOTHEEK
-- ============================================

CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bestandsnaam VARCHAR(255) NOT NULL,
    originele_naam VARCHAR(255),
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    type VARCHAR(50),
    grootte INTEGER,
    breedte INTEGER,
    hoogte INTEGER,
    alt_tekst VARCHAR(255),
    beschrijving TEXT,
    map VARCHAR(255) DEFAULT '/',
    geupload_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- COMMENTAREN
-- ============================================

CREATE TABLE commentaren (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    artikel_id UUID REFERENCES artikelen(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    parent_id UUID REFERENCES commentaren(id) ON DELETE CASCADE,
    naam VARCHAR(255),
    email VARCHAR(255),
    inhoud TEXT NOT NULL,
    goedgekeurd BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- NIEUWSBRIEF
-- ============================================

CREATE TABLE nieuwsbrief_abonnees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    naam VARCHAR(255),
    actief BOOLEAN DEFAULT TRUE,
    bevestigd BOOLEAN DEFAULT FALSE,
    bevestigings_token VARCHAR(255),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE nieuwsbrief_campagnes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    onderwerp VARCHAR(255) NOT NULL,
    inhoud TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'concept' CHECK (status IN (
        'concept', 'gepland', 'verstuurd'
    )),
    geplande_verzending TIMESTAMPTZ,
    verstuurd_op TIMESTAMPTZ,
    ontvanger_count INTEGER DEFAULT 0,
    open_count INTEGER DEFAULT 0,
    klik_count INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MENU & NAVIGATIE
-- ============================================

CREATE TABLE menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_locatie VARCHAR(50) DEFAULT 'hoofd',
    label VARCHAR(255) NOT NULL,
    url VARCHAR(500),
    pagina_id UUID REFERENCES paginas(id) ON DELETE SET NULL,
    parent_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
    volgorde INTEGER DEFAULT 0,
    nieuw_tabblad BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE
);

-- ============================================
-- SEO & ANALYTICS
-- ============================================

CREATE TABLE seo_instellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleutel VARCHAR(100) UNIQUE NOT NULL,
    waarde TEXT,
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO seo_instellingen (sleutel, waarde) VALUES
('site_naam', '{{SITE_NAAM}}'),
('site_beschrijving', '{{SITE_BESCHRIJVING}}'),
('site_url', '{{SITE_URL}}'),
('google_analytics_id', '{{GA_ID}}'),
('robots_txt', 'User-agent: *\nAllow: /'),
('sitemap_actief', 'true');

-- ============================================
-- SITE INSTELLINGEN
-- ============================================

CREATE TABLE instellingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleutel VARCHAR(100) UNIQUE NOT NULL,
    waarde TEXT,
    type VARCHAR(20) DEFAULT 'tekst',
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO instellingen (sleutel, waarde, type) VALUES
('site_naam', '{{SITE_NAAM}}', 'tekst'),
('site_email', '{{SITE_EMAIL}}', 'tekst'),
('artikelen_per_pagina', '12', 'getal'),
('commentaar_moderatie', 'true', 'boolean'),
('nieuwsbrief_actief', 'true', 'boolean'),
('registratie_open', 'false', 'boolean');

-- ============================================
-- INDEXEN
-- ============================================

CREATE INDEX idx_artikelen_slug ON artikelen(slug);
CREATE INDEX idx_artikelen_status ON artikelen(status);
CREATE INDEX idx_artikelen_auteur ON artikelen(auteur_id);
CREATE INDEX idx_artikelen_gepubliceerd ON artikelen(gepubliceerd_op);
CREATE INDEX idx_artikelen_zoek ON artikelen USING gin(titel gin_trgm_ops);
CREATE INDEX idx_paginas_slug ON paginas(slug);
CREATE INDEX idx_gebruikers_email ON gebruikers(email);
CREATE INDEX idx_tags_slug ON tags(slug);

-- ============================================
-- AUTOMATISCHE TIMESTAMPS & LEESTIJD
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN NEW.bijgewerkt_op = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bereken_leestijd()
RETURNS TRIGGER AS $$
BEGIN
    NEW.leestijd_minuten = GREATEST(1, CEIL(array_length(string_to_array(NEW.inhoud, ' '), 1)::DECIMAL / 200));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_artikelen_bijgewerkt BEFORE UPDATE ON artikelen FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_paginas_bijgewerkt BEFORE UPDATE ON paginas FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_leestijd BEFORE INSERT OR UPDATE ON artikelen FOR EACH ROW EXECUTE FUNCTION bereken_leestijd();
