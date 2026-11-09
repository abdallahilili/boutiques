-- Données de départ pour l'environnement local (supabase db reset).
-- Les rôles, permissions, le plan d'essai, les thèmes et les référentiels par défaut des boutiques
-- sont créés par les migrations / creer_boutique_avec_defauts. Ici : les plans payants d'exemple.
-- Les prix sont des valeurs d'exemple à ajuster dans app_admin (Plans).

insert into public.plans (code, nom_ar, nom_fr, description_ar, description_fr, prix_mensuel, prix_annuel, limites, ordre)
values
  ('standard', 'قياسي', 'Standard',
   'للمتاجر الصغيرة والمتوسطة', 'Pour les boutiques petites et moyennes',
   500, 5000,
   '{"utilisateurs": 3, "produits": 1000, "stockage_mo": 2048, "boutique_en_ligne": true, "domaine_personnalise": false, "themes": 3, "rapports_avances": true}'::jsonb,
   1),
  ('premium', 'مميز', 'Premium',
   'كل الميزات مع نطاق خاص', 'Toutes les fonctions avec domaine personnalisé',
   1000, 10000,
   '{"utilisateurs": 10, "produits": null, "stockage_mo": 10240, "boutique_en_ligne": true, "domaine_personnalise": true, "themes": null, "rapports_avances": true}'::jsonb,
   2)
on conflict (code) do nothing;
