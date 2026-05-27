-- ═══════════════════════════════════════════════════════════
-- ACQORA CRM — SQL SETUP COMPLET
-- Coller intégralement dans Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════

-- ─── EXTENSIONS ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── TABLES (IF NOT EXISTS pour rejouer sans erreur) ─────────

CREATE TABLE IF NOT EXISTS setters (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  prenom TEXT NOT NULL,
  nom TEXT NOT NULL,
  email TEXT UNIQUE,
  telephone TEXT,
  role TEXT DEFAULT 'setter' CHECK (role IN ('setter','closer','manager','admin')),
  pole TEXT DEFAULT 'both' CHECK (pole IN ('b2b','b2c','both')),
  actif BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
  score_interet INTEGER DEFAULT 0,          -- ← colonne note étoiles
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
  )),                                       -- ← colonne espace client
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

CREATE TABLE IF NOT EXISTS historique (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type_cible TEXT NOT NULL CHECK (type_cible IN ('client','lead_b2c','rdv')),
  cible_id UUID NOT NULL,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type_cible TEXT NOT NULL CHECK (type_cible IN ('client','lead_b2c')),
  cible_id UUID NOT NULL,
  setter_id UUID REFERENCES setters(id) ON DELETE SET NULL,
  contenu TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── COLONNES SUPPLÉMENTAIRES (si tables déjà créées) ────────
-- setters : colonne pole (manquante si table créée avec un ancien schéma)
ALTER TABLE setters    ADD COLUMN IF NOT EXISTS pole TEXT DEFAULT 'both'
  CHECK (pole IN ('b2b','b2c','both'));
ALTER TABLE setters    ADD COLUMN IF NOT EXISTS actif BOOLEAN DEFAULT true;

-- clients : note étoiles
ALTER TABLE clients    ADD COLUMN IF NOT EXISTS score_interet INTEGER DEFAULT 0;
ALTER TABLE clients    ADD COLUMN IF NOT EXISTS token_acces TEXT;

-- leads_b2c : statut contact espace client
ALTER TABLE leads_b2c  ADD COLUMN IF NOT EXISTS statut_contact TEXT DEFAULT 'a_appeler'
  CHECK (statut_contact IN ('a_appeler','appele','devis_envoye','signe','perdu'));

-- ─── TRIGGERS updated_at ─────────────────────────────────────
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

-- ─── RLS (politiques ouvertes MVP) ───────────────────────────
ALTER TABLE setters    ENABLE ROW LEVEL SECURITY;
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

-- ─── DONNÉES DE DÉMO ─────────────────────────────────────────
-- (ON CONFLICT DO NOTHING = safe à rejouer)

INSERT INTO setters (prenom, nom, email, role, pole) VALUES
  ('Marie',  'Setter',  'marie@acqora.fr',   'setter',  'b2c'),
  ('Thomas', 'Setter',  'thomas@acqora.fr',  'setter',  'b2b'),
  ('Krys',   'Manager', 'contact@acqora.fr', 'manager', 'both')
ON CONFLICT (email) DO NOTHING;

INSERT INTO clients (nom_entreprise, prenom_dirigeant, nom_dirigeant, telephone, email,
  secteur, zone_intervention, offre, statut_client, score_interet, source) VALUES
  ('Plomberie Martin', 'Marc',    'Martin', '+33635212738', 'marc.martin@gmail.com',
   'plomberie',  'Bordeaux + 30km',      'decouverte',    'client_actif',     4, 'meta_ads_b2b'),
  ('PAC Solutions',    'Laurent', 'Papin',  '+33601263348', 'lpapin@gmail.com',
   'pac',         'Gironde',              'mensuel_rdv',   'client_actif',     5, 'meta_ads_b2b'),
  ('Elec Pro 33',      'Chynel',  'Gerard', '+33617712133', 'chynel.gerard@gmail.com',
   'electricite', 'Bordeaux Métropole',  'mensuel_leads', 'en_qualification', 3, 'meta_ads_b2b'),
  ('Isolation Sud',    'Pierre',  'Dubois', '+33611223344', 'p.dubois@isolation-sud.fr',
   'isolation',   'Gironde + Lot-et-Garonne', NULL,       'prospect_b2b',     0, 'meta_ads_b2b'),
  ('Toiture Expert',   'Jean',    'Blanc',  '+33622334455', 'j.blanc@toiture.fr',
   'couverture',  'Bordeaux + 50km',     NULL,            'interesse',        2, 'meta_ads_b2b')
ON CONFLICT (email) DO NOTHING;

INSERT INTO leads_b2c (nom_complet, telephone, email, type_travaux, zone, statut,
  crit_identite, crit_besoin, crit_decideur, crit_budget, crit_delai, crit_decision_proche,
  budget_estime, delai_projet, prix_facturation, meta_lead_id) VALUES
  ('Jean Dupont',      '+33612345678', 'jean.dupont@gmail.com',    'pac',              'Bordeaux',
   'qualifie',             true,  true,  true,  true,  true,  true,  '8000-12000€', '< 2 mois',  89.00, 'demo_001'),
  ('Sophie Lemaire',   '+33698765432', 'sophie.lemaire@free.fr',   'isolation',        'Mérignac',
   'en_cours',             true,  true,  true,  false, false, false, NULL,           NULL,         59.00, 'demo_002'),
  ('Paul Moreau',      '+33677889900', 'p.moreau@orange.fr',       'renovation_globale','Pessac',
   'nouveau',              false, false, false, false, false, false, NULL,           NULL,         89.00, 'demo_003'),
  ('Isabelle Martin',  '+33655443322', 'i.martin@gmail.com',       'photovoltaique',   'Libourne',
   'partiellement_qualifie', true, true, true,  true,  false, false, '12000-18000€','3 mois',     89.00, 'demo_004'),
  ('Robert Durand',    '+33644332211', 'r.durand@sfr.fr',          'chauffage',        'Arcachon',
   'injoignable',          false, false, false, false, false, false, NULL,           NULL,         59.00, 'demo_005')
ON CONFLICT (meta_lead_id) DO NOTHING;

-- ─── REALTIME (activer sur les tables) ───────────────────────
-- Dans Supabase → Database → Replication, activer pour :
-- clients, leads_b2c, rdv
-- (ne peut pas être fait en SQL, doit être activé dans l'interface)
