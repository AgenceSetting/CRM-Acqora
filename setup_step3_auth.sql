-- ══════════════════════════════════════════════════════════════
-- ÉTAPE 3 — AUTHENTIFICATION SETTERS + TOKENS CLIENTS
-- Coller dans Supabase → SQL Editor → Run
-- ══════════════════════════════════════════════════════════════

-- 1. Ajouter la colonne password aux setters
ALTER TABLE setters ADD COLUMN IF NOT EXISTS password TEXT;

-- 2. Définir les mots de passe des setters de démo
UPDATE setters SET password = 'marie123'  WHERE email = 'marie@acqora.fr';
UPDATE setters SET password = 'thomas123' WHERE email = 'thomas@acqora.fr';
UPDATE setters SET password = 'krys123'   WHERE email = 'contact@acqora.fr';

-- 3. Ajouter des token_acces aux clients actifs de démo
-- (ces tokens servent à générer les liens espace client)
UPDATE clients
SET token_acces = 'demo_token_plomberie_martin_2024'
WHERE email = 'marc.martin@gmail.com' AND token_acces IS NULL;

UPDATE clients
SET token_acces = 'demo_token_pac_solutions_2024'
WHERE email = 'lpapin@gmail.com' AND token_acces IS NULL;

-- 4. Vérification
SELECT id, prenom, nom, email, role, pole, actif,
       CASE WHEN password IS NOT NULL THEN '✅ défini' ELSE '❌ manquant' END AS "Mot de passe"
FROM setters
ORDER BY role;

SELECT id, nom_entreprise, statut_client,
       CASE WHEN token_acces IS NOT NULL THEN '✅ ' || LEFT(token_acces,20)||'...' ELSE '❌ pas de token' END AS "Espace client"
FROM clients
ORDER BY statut_client;
