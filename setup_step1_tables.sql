-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 1 — CRÉER LES TABLES (coller dans SQL Editor → Run)
-- ══════════════════════════════════════════════════════════════

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Setters (table déjà existante → on ajoute juste les colonnes manquantes)
ALTER TABLE setters ADD COLUMN IF NOT EXISTS pole TEXT DEFAULT 'both'
  CHECK (pole IN ('b2b','b2c','both'));
ALTER TABLE setters ADD COLUMN IF NOT EXISTS actif BOOLEAN DEFAULT true;

-- Clients B2B
CREATE TABLE IF NOT EXISTS clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom_entreprise TEXT NOT NULL,
  prenom_dirigeant TEXT,
  nom_dirigeant TEXT,
  siret TEXT,
  telephone TEXT,
  email TEXT UNIQUE NOT NULL,
  secteur TEXT CHECK (secteur IN (
    'plomberie','electricite','hvac','menuiserie','peinture',
    'couverture','maconnerie','isolation','photovoltaique',
    'pac','renovation_globale','autre'
  )),
  zone_intervention TEXT,
  departements TEXT[],
  offre TEXT CHECK (offre IN ('decouverte','mensuel_leads','mensuel_rdv','sur_mesure')),
  statut_client TEXT DEFAULT 'prospect_b2b' CHECK (statut_client IN (
    'prospect_b2b','en_qualification','interesse',
    'client_actif','client_pause','perdu'
  )),
  score_interet INTEGER DEFAULT 0,
  password_hash TEXT,
  token_acces TEXT UNIQUE,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  date_premier_contact TIMESTAMPTZ,
  date_signature TIMESTAMPTZ,
  notes_commerciales TEXT,
  meta_lead_id TEXT,
  source TEXT DEFAULT 'meta_ads_b2b',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Leads B2C
CREATE TABLE IF NOT EXISTS leads_b2c (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom_complet TEXT NOT NULL,
  telephone TEXT,
  email TEXT,
  zone TEXT,
  type_travaux TEXT CHECK (type_travaux IN (
    'pac','isolation','photovoltaique','plomberie','electricite',
    'hvac','renovation_globale','chauffage','couverture',
    'menuiserie','peinture','autre'
  )),
  surface_m2 TEXT,
  type_logement TEXT CHECK (type_logement IN ('maison','appartement','local_commercial','autre')),
  statut TEXT DEFAULT 'nouveau' CHECK (statut IN (
    'nouveau','en_cours','qualifie','partiellement_qualifie',
    'non_qualifie','livre','injoignable'
  )),
  statut_contact TEXT DEFAULT 'a_appeler' CHECK (statut_contact IN (
    'a_appeler','appele','devis_envoye','signe','perdu'
  )),
  crit_identite BOOLEAN DEFAULT false,
  crit_besoin BOOLEAN DEFAULT false,
  crit_decideur BOOLEAN DEFAULT false,
  crit_budget BOOLEAN DEFAULT false,
  crit_delai BOOLEAN DEFAULT false,
  crit_decision_proche BOOLEAN DEFAULT false,
  budget_estime TEXT,
  delai_projet TEXT,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  date_livraison TIMESTAMPTZ,
  prix_facturation DECIMAL(10,2),
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  nb_tentatives_appel INTEGER DEFAULT 0,
  derniere_tentative TIMESTAMPTZ,
  meta_lead_id TEXT UNIQUE,
  meta_form_id TEXT,
  meta_ad_id TEXT,
  meta_campaign_id TEXT,
  meta_adset_id TEXT,
  source TEXT DEFAULT 'meta_ads_b2c',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RDV
CREATE TABLE IF NOT EXISTS rdv (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_b2c_id UUID REFERENCES leads_b2c(id) ON DELETE SET NULL,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  prospect_nom TEXT NOT NULL,
  prospect_telephone TEXT,
  prospect_email TEXT,
  prospect_besoin TEXT,
  date_rdv DATE NOT NULL,
  heure_rdv TIME NOT NULL,
  type_rdv TEXT DEFAULT 'telephone' CHECK (type_rdv IN ('telephone','visio','physique')),
  statut TEXT DEFAULT 'confirme' CHECK (statut IN (
    'confirme','honore','no_show','annule_prospect','annule_client'
  )),
  facturable BOOLEAN DEFAULT true,
  prix_facturation DECIMAL(10,2) DEFAULT 116.00,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Historique
CREATE TABLE IF NOT EXISTS historique (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type_cible TEXT NOT NULL CHECK (type_cible IN ('client','lead_b2c','rdv')),
  cible_id UUID NOT NULL,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notes
CREATE TABLE IF NOT EXISTS notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type_cible TEXT NOT NULL CHECK (type_cible IN ('client','lead_b2c')),
  cible_id UUID NOT NULL,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  contenu TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Triggers updated_at
CREATE OR REPLACE FUNCTION fn_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_clients_updated ON clients;
CREATE TRIGGER tr_clients_updated
  BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

DROP TRIGGER IF EXISTS tr_leads_b2c_updated ON leads_b2c;
CREATE TRIGGER tr_leads_b2c_updated
  BEFORE UPDATE ON leads_b2c FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- RLS
ALTER TABLE clients    ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads_b2c  ENABLE ROW LEVEL SECURITY;
ALTER TABLE rdv        ENABLE ROW LEVEL SECURITY;
ALTER TABLE historique ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes      ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "all_setters"    ON setters;
DROP POLICY IF EXISTS "all_clients"    ON clients;
DROP POLICY IF EXISTS "all_leads_b2c"  ON leads_b2c;
DROP POLICY IF EXISTS "all_rdv"        ON rdv;
DROP POLICY IF EXISTS "all_historique" ON historique;
DROP POLICY IF EXISTS "all_notes"      ON notes;

CREATE POLICY "all_setters"    ON setters    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "all_clients"    ON clients    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "all_leads_b2c"  ON leads_b2c  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "all_rdv"        ON rdv        FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "all_historique" ON historique FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "all_notes"      ON notes      FOR ALL USING (true) WITH CHECK (true);
