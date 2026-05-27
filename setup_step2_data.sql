-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 2 — DONNÉES DE DÉMO (coller après l'étape 1)
-- ══════════════════════════════════════════════════════════════

-- Setters
INSERT INTO setters (prenom, nom, email, role, pole) VALUES
  ('Marie',  'Setter',  'marie@acqora.fr',   'setter',  'b2c'),
  ('Thomas', 'Setter',  'thomas@acqora.fr',  'setter',  'b2b'),
  ('Krys',   'Manager', 'contact@acqora.fr', 'manager', 'both')
ON CONFLICT (email) DO UPDATE SET
  pole = EXCLUDED.pole,
  role = EXCLUDED.role;

-- Clients B2B (5 entreprises artisans)
INSERT INTO clients (
  nom_entreprise, prenom_dirigeant, nom_dirigeant,
  telephone, email, secteur, zone_intervention,
  offre, statut_client, score_interet, source
) VALUES
  ('Plomberie Martin', 'Marc',    'Martin',
   '+33635212738', 'marc.martin@gmail.com',
   'plomberie',  'Bordeaux + 30km',
   'decouverte',    'client_actif',     4, 'meta_ads_b2b'),

  ('PAC Solutions',    'Laurent', 'Papin',
   '+33601263348', 'lpapin@gmail.com',
   'pac',         'Gironde',
   'mensuel_rdv',   'client_actif',     5, 'meta_ads_b2b'),

  ('Elec Pro 33',      'Chynel',  'Gerard',
   '+33617712133', 'chynel.gerard@gmail.com',
   'electricite', 'Bordeaux Métropole',
   'mensuel_leads', 'en_qualification', 3, 'meta_ads_b2b'),

  ('Isolation Sud',    'Pierre',  'Dubois',
   '+33611223344', 'p.dubois@isolation-sud.fr',
   'isolation',   'Gironde + Lot-et-Garonne',
   NULL,            'prospect_b2b',     0, 'meta_ads_b2b'),

  ('Toiture Expert',   'Jean',    'Blanc',
   '+33622334455', 'j.blanc@toiture.fr',
   'couverture',  'Bordeaux + 50km',
   NULL,            'interesse',        2, 'meta_ads_b2b')
ON CONFLICT (email) DO NOTHING;

-- Leads B2C (5 particuliers)
INSERT INTO leads_b2c (
  nom_complet, telephone, email, type_travaux, zone, statut,
  crit_identite, crit_besoin, crit_decideur, crit_budget, crit_delai, crit_decision_proche,
  budget_estime, delai_projet, prix_facturation, meta_lead_id
) VALUES
  ('Jean Dupont',
   '+33612345678', 'jean.dupont@gmail.com',
   'pac',               'Bordeaux',
   'qualifie',
   true,  true,  true,  true,  true,  true,
   '8000-12000€', '< 2 mois',  89.00, 'demo_001'),

  ('Sophie Lemaire',
   '+33698765432', 'sophie.lemaire@free.fr',
   'isolation',         'Mérignac',
   'en_cours',
   true,  true,  true,  false, false, false,
   NULL,           NULL,         59.00, 'demo_002'),

  ('Paul Moreau',
   '+33677889900', 'p.moreau@orange.fr',
   'renovation_globale', 'Pessac',
   'nouveau',
   false, false, false, false, false, false,
   NULL,           NULL,         89.00, 'demo_003'),

  ('Isabelle Martin',
   '+33655443322', 'i.martin@gmail.com',
   'photovoltaique',    'Libourne',
   'partiellement_qualifie',
   true,  true,  true,  true,  false, false,
   '12000-18000€', '3 mois',    89.00, 'demo_004'),

  ('Robert Durand',
   '+33644332211', 'r.durand@sfr.fr',
   'chauffage',         'Arcachon',
   'injoignable',
   false, false, false, false, false, false,
   NULL,           NULL,         59.00, 'demo_005')
ON CONFLICT (meta_lead_id) DO NOTHING;
