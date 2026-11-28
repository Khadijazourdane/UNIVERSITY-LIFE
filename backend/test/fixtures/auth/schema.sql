-- Fixture locale réservée aux essais Auth.
DO $fixture$
BEGIN
  IF current_database() <> 'university_life_auth_test' THEN
    RAISE EXCEPTION 'Cette fixture est réservée à la base university_life_auth_test.';
  END IF;
END;
$fixture$;

CREATE TABLE public.utilisateur (
  id_utilisateur INT PRIMARY KEY,
  nom VARCHAR(60) NOT NULL,
  prenom VARCHAR(60) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  mot_de_passe VARCHAR(255) NOT NULL,
  role VARCHAR(10) NOT NULL CHECK (role IN ('etudiant', 'professeur', 'admin'))
);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO university_life_auth_test_app;
GRANT SELECT ON public.utilisateur TO university_life_auth_test_app;
GRANT UPDATE (mot_de_passe) ON public.utilisateur TO university_life_auth_test_app;
