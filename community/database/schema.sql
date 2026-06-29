-- ============================================
-- ARC COMMUNITY BACKEND TEMPLATE
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
    gebruikersnaam VARCHAR(100) UNIQUE NOT NULL,
    weergavenaam VARCHAR(255),
    bio TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    website_url TEXT,
    locatie VARCHAR(255),
    rol VARCHAR(20) DEFAULT 'lid' CHECK (rol IN ('lid', 'moderator', 'redacteur', 'admin')),
    email_geverifieerd BOOLEAN DEFAULT FALSE,
    actief BOOLEAN DEFAULT TRUE,
    geblokkeerd BOOLEAN DEFAULT FALSE,
    blokkeringreden TEXT,
    geblokkeerd_tot TIMESTAMPTZ,
    punten INTEGER DEFAULT 0,
    niveau INTEGER DEFAULT 1,
    laatste_actief TIMESTAMPTZ,
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
-- GROEPEN & KANALEN
-- ============================================

CREATE TABLE groepen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    beschrijving TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    type VARCHAR(20) DEFAULT 'openbaar' CHECK (type IN ('openbaar', 'besloten', 'prive')),
    categorie VARCHAR(100),
    leden_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    actief BOOLEAN DEFAULT TRUE,
    aangemaakt_door UUID REFERENCES gebruikers(id),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE groep_leden (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    groep_id UUID REFERENCES groepen(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    rol VARCHAR(20) DEFAULT 'lid' CHECK (rol IN ('lid', 'moderator', 'beheerder')),
    status VARCHAR(20) DEFAULT 'actief' CHECK (status IN ('uitgenodigd', 'aangevraagd', 'actief', 'geblokkeerd')),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(groep_id, gebruiker_id)
);

-- ============================================
-- POSTS & CONTENT
-- ============================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auteur_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    groep_id UUID REFERENCES groepen(id) ON DELETE CASCADE,
    titel VARCHAR(500),
    inhoud TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'tekst' CHECK (type IN (
        'tekst', 'afbeelding', 'video', 'link', 'poll', 'evenement'
    )),
    status VARCHAR(20) DEFAULT 'gepubliceerd' CHECK (status IN (
        'concept', 'gepubliceerd', 'verborgen', 'verwijderd', 'geblokkeerd'
    )),
    uitgelicht BOOLEAN DEFAULT FALSE,
    vastgezet BOOLEAN DEFAULT FALSE,
    reacties_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    weergaven INTEGER DEFAULT 0,
    link_url TEXT,
    link_preview JSONB,
    meta_data JSONB,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE post_afbeeldingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    alt_tekst VARCHAR(255),
    volgorde INTEGER DEFAULT 0
);

CREATE TABLE post_tags (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    PRIMARY KEY (post_id, tag)
);

-- ============================================
-- REACTIES
-- ============================================

CREATE TABLE reacties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    auteur_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    parent_id UUID REFERENCES reacties(id) ON DELETE CASCADE,
    inhoud TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'gepubliceerd' CHECK (status IN (
        'gepubliceerd', 'verborgen', 'verwijderd'
    )),
    likes_count INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    bijgewerkt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- LIKES & REACTIES
-- ============================================

CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(20) CHECK (type IN ('post', 'reactie')),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    reactie_id UUID REFERENCES reacties(id) ON DELETE CASCADE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(gebruiker_id, post_id),
    UNIQUE(gebruiker_id, reactie_id)
);

CREATE TABLE emoji_reacties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(gebruiker_id, post_id, emoji)
);

-- ============================================
-- VOLGEN & CONNECTIES
-- ============================================

CREATE TABLE volgers (
    volger_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    gevolgde_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (volger_id, gevolgde_id)
);

-- ============================================
-- BERICHTEN
-- ============================================

CREATE TABLE gesprekken (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) DEFAULT 'privé' CHECK (type IN ('privé', 'groep')),
    naam VARCHAR(255),
    aangemaakt_door UUID REFERENCES gebruikers(id),
    laatste_bericht_op TIMESTAMPTZ,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gesprek_deelnemers (
    gesprek_id UUID REFERENCES gesprekken(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    ongelezen_count INTEGER DEFAULT 0,
    gedempt BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (gesprek_id, gebruiker_id)
);

CREATE TABLE berichten (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gesprek_id UUID REFERENCES gesprekken(id) ON DELETE CASCADE,
    verzender_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    inhoud TEXT NOT NULL,
    bijlage_url TEXT,
    bijlage_type VARCHAR(20),
    gelezen BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- EVENEMENTEN
-- ============================================

CREATE TABLE evenementen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    groep_id UUID REFERENCES groepen(id) ON DELETE CASCADE,
    organisator_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    titel VARCHAR(500) NOT NULL,
    slug VARCHAR(500) UNIQUE NOT NULL,
    beschrijving TEXT,
    afbeelding_url TEXT,
    type VARCHAR(20) DEFAULT 'aanwezig' CHECK (type IN ('aanwezig', 'online', 'hybride')),
    locatie TEXT,
    online_url TEXT,
    start_datetime TIMESTAMPTZ NOT NULL,
    eind_datetime TIMESTAMPTZ,
    max_deelnemers INTEGER,
    deelnemers_count INTEGER DEFAULT 0,
    prijs DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'gepland' CHECK (status IN (
        'concept', 'gepland', 'actief', 'afgelopen', 'geannuleerd'
    )),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE evenement_deelnemers (
    evenement_id UUID REFERENCES evenementen(id) ON DELETE CASCADE,
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'gaat' CHECK (status IN ('gaat', 'misschien', 'gaat_niet')),
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (evenement_id, gebruiker_id)
);

-- ============================================
-- BADGES & GAMIFICATION
-- ============================================

CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    naam VARCHAR(100) NOT NULL,
    beschrijving TEXT,
    icoon_url TEXT,
    emoji VARCHAR(10),
    type VARCHAR(30),
    punten_waarde INTEGER DEFAULT 0,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gebruiker_badges (
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (gebruiker_id, badge_id)
);

-- ============================================
-- NOTIFICATIES
-- ============================================

CREATE TABLE notificaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE CASCADE,
    type VARCHAR(50) CHECK (type IN (
        'nieuwe_reactie', 'nieuwe_like', 'nieuwe_volger',
        'groep_uitnodiging', 'evenement_herinnering',
        'bericht', 'badge_verdiend', 'melding'
    )),
    titel VARCHAR(255),
    inhoud TEXT,
    actie_url TEXT,
    afbeelding_url TEXT,
    gelezen BOOLEAN DEFAULT FALSE,
    aangemaakt_op TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MODERATIE & MELDINGEN
-- ============================================

CREATE TABLE meldingen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    melder_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    type VARCHAR(20) CHECK (type IN ('post', 'reactie', 'gebruiker', 'bericht')),
    post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    reactie_id UUID REFERENCES reacties(id) ON DELETE SET NULL,
    gemelde_gebruiker_id UUID REFERENCES gebruikers(id) ON DELETE SET NULL,
    reden VARCHAR(50) CHECK (reden IN (
        'spam', 'haatzaaiing', 'ongepast', 'geweld',
        'desinformatie', 'auteursrecht', 'anders'
    )),
    beschrijving TEXT,
    status VARCHAR(20) DEFAULT 'nieuw' CHECK (status IN (
        'nieuw', 'in_behandeling', 'opgelost', 'afgewezen'
    )),
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
('community_naam', '{{COMMUNITY_NAAM}}', 'tekst'),
('community_email', '{{COMMUNITY_EMAIL}}', 'tekst'),
('community_url', '{{COMMUNITY_URL}}', 'tekst'),
('community_beschrijving', '{{COMMUNITY_BESCHRIJVING}}', 'tekst'),
('registratie_open', 'true', 'boolean'),
('email_verificatie', 'true', 'boolean'),
('moderatie_actief', 'true', 'boolean'),
('berichten_actief', 'true', 'boolean'),
('evenementen_actief', 'true', 'boolean'),
('gamification_actief', 'true', 'boolean');

-- ============================================
-- INDEXEN
-- ============================================

CREATE INDEX idx_posts_groep ON posts(groep_id);
CREATE INDEX idx_posts_auteur ON posts(auteur_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_aangemaakt ON posts(aangemaakt_op DESC);
CREATE INDEX idx_posts_zoek ON posts USING gin(inhoud gin_trgm_ops);
CREATE INDEX idx_reacties_post ON reacties(post_id);
CREATE INDEX idx_notificaties_gebruiker ON notificaties(gebruiker_id, gelezen);
CREATE INDEX idx_berichten_gesprek ON berichten(gesprek_id);
CREATE INDEX idx_gebruikers_naam ON gebruikers(gebruikersnaam);
CREATE INDEX idx_groepen_slug ON groepen(slug);

-- ============================================
-- AUTOMATISCHE TIMESTAMPS & TELLERS
-- ============================================

CREATE OR REPLACE FUNCTION update_bijgewerkt_op()
RETURNS TRIGGER AS $$
BEGIN NEW.bijgewerkt_op = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_gebruikers_bijgewerkt BEFORE UPDATE ON gebruikers FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_posts_bijgewerkt BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();
CREATE TRIGGER tr_groepen_bijgewerkt BEFORE UPDATE ON groepen FOR EACH ROW EXECUTE FUNCTION update_bijgewerkt_op();

-- AUTO LIKES TELLER
CREATE OR REPLACE FUNCTION update_likes_teller()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.post_id IS NOT NULL THEN
            UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        END IF;
        IF NEW.reactie_id IS NOT NULL THEN
            UPDATE reacties SET likes_count = likes_count + 1 WHERE id = NEW.reactie_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.post_id IS NOT NULL THEN
            UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
        END IF;
        IF OLD.reactie_id IS NOT NULL THEN
            UPDATE reacties SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.reactie_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_likes_teller
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW EXECUTE FUNCTION update_likes_teller();

-- AUTO REACTIES TELLER
CREATE OR REPLACE FUNCTION update_reacties_teller()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET reacties_count = reacties_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET reacties_count = GREATEST(0, reacties_count - 1) WHERE id = OLD.post_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_reacties_teller
    AFTER INSERT OR DELETE ON reacties
    FOR EACH ROW EXECUTE FUNCTION update_reacties_teller();

-- AUTO LEDEN TELLER
CREATE OR REPLACE FUNCTION update_leden_teller()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE groepen SET leden_count = leden_count + 1 WHERE id = NEW.groep_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE groepen SET leden_count = GREATEST(0, leden_count - 1) WHERE id = OLD.groep_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_leden_teller
    AFTER INSERT OR DELETE ON groep_leden
    FOR EACH ROW EXECUTE FUNCTION update_leden_teller();
