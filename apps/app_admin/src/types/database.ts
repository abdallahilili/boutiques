// Fichier généré par scripts/gen_types.mjs à partir de supabase/migrations — ne pas modifier à la main.
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  public: {
    Tables: {
        abonnements: {
        Row: {
          id: string
          boutique_id: string
          plan_id: string
          statut: Database['public']['Enums']['statut_abonnement']
          debut_le: string
          fin_le: string | null
          grace_jusqu_au: string | null
          renouvellement_auto: boolean
          remise: number
          notes: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          plan_id: string
          statut?: Database['public']['Enums']['statut_abonnement']
          debut_le?: string
          fin_le?: string | null
          grace_jusqu_au?: string | null
          renouvellement_auto?: boolean
          remise?: number
          notes?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          plan_id?: string
          statut?: Database['public']['Enums']['statut_abonnement']
          debut_le?: string
          fin_le?: string | null
          grace_jusqu_au?: string | null
          renouvellement_auto?: boolean
          remise?: number
          notes?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        ajustements_stock: {
        Row: {
          id: string
          boutique_id: string
          type: Database['public']['Enums']['type_ajustement_stock']
          motif_id: string | null
          note: string | null
          utilisateur_id: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          type: Database['public']['Enums']['type_ajustement_stock']
          motif_id?: string | null
          note?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          type?: Database['public']['Enums']['type_ajustement_stock']
          motif_id?: string | null
          note?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        appareils: {
        Row: {
          id: string
          utilisateur_id: string
          boutique_id: string | null
          jeton_fcm: string | null
          plateforme: Database['public']['Enums']['plateforme_appareil']
          nom: string | null
          derniere_activite: string
          cree_le: string
        }
        Insert: {
          id?: string
          utilisateur_id: string
          boutique_id?: string | null
          jeton_fcm?: string | null
          plateforme: Database['public']['Enums']['plateforme_appareil']
          nom?: string | null
          derniere_activite?: string
          cree_le?: string
        }
        Update: {
          id?: string
          utilisateur_id?: string
          boutique_id?: string | null
          jeton_fcm?: string | null
          plateforme?: Database['public']['Enums']['plateforme_appareil']
          nom?: string | null
          derniere_activite?: string
          cree_le?: string
        }
        Relationships: []
        }
        bannieres_site: {
        Row: {
          id: string
          boutique_id: string
          image_url: string
          titre_ar: string | null
          titre_fr: string | null
          lien: string | null
          ordre: number
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          image_url: string
          titre_ar?: string | null
          titre_fr?: string | null
          lien?: string | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          image_url?: string
          titre_ar?: string | null
          titre_fr?: string | null
          lien?: string | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        boutiques: {
        Row: {
          id: string
          commercante_id: string
          nom_ar: string | null
          nom_fr: string | null
          slug: string
          code_boutique: string
          type_activite: string | null
          logo_url: string | null
          telephone: string | null
          whatsapp: string | null
          adresse: string | null
          ville: string | null
          devise: string
          langue_par_defaut: string
          fuseau_horaire: string
          statut: Database['public']['Enums']['statut_boutique']
          parametres: Json
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          commercante_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          slug: string
          code_boutique: string
          type_activite?: string | null
          logo_url?: string | null
          telephone?: string | null
          whatsapp?: string | null
          adresse?: string | null
          ville?: string | null
          devise?: string
          langue_par_defaut?: string
          fuseau_horaire?: string
          statut?: Database['public']['Enums']['statut_boutique']
          parametres?: Json
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          commercante_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          slug?: string
          code_boutique?: string
          type_activite?: string | null
          logo_url?: string | null
          telephone?: string | null
          whatsapp?: string | null
          adresse?: string | null
          ville?: string | null
          devise?: string
          langue_par_defaut?: string
          fuseau_horaire?: string
          statut?: Database['public']['Enums']['statut_boutique']
          parametres?: Json
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        categories: {
        Row: {
          id: string
          boutique_id: string
          parent_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          image_url: string | null
          ordre: number
          visible_en_ligne: boolean
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
          icone: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          parent_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          image_url?: string | null
          ordre?: number
          visible_en_ligne?: boolean
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          icone?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          parent_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          image_url?: string | null
          ordre?: number
          visible_en_ligne?: boolean
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          icone?: string | null
        }
        Relationships: []
        }
        categories_depenses: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        clients: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          telephone: string | null
          whatsapp: string | null
          adresse: string | null
          ville: string | null
          plafond_credit: number | null
          solde: number
          notes: string | null
          cree_par: string | null
          cree_le: string
          modifie_le: string
          supprime_le: string | null
          boutique_liee_id: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          whatsapp?: string | null
          adresse?: string | null
          ville?: string | null
          plafond_credit?: number | null
          solde?: number
          notes?: string | null
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
          boutique_liee_id?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          whatsapp?: string | null
          adresse?: string | null
          ville?: string | null
          plafond_credit?: number | null
          solde?: number
          notes?: string | null
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
          boutique_liee_id?: string | null
        }
        Relationships: []
        }
        commandes: {
        Row: {
          id: string
          boutique_id: string
          numero: string
          canal: Database['public']['Enums']['canal_vente']
          client_id: string | null
          compte_client_id: string | null
          nom_client: string
          telephone: string
          adresse: string | null
          ville: string | null
          zone_id: string | null
          mode_livraison: Database['public']['Enums']['mode_livraison']
          frais_livraison: number
          statut: Database['public']['Enums']['statut_commande']
          statut_paiement: Database['public']['Enums']['statut_paiement_commande']
          mode_paiement: Database['public']['Enums']['mode_paiement_commande']
          sous_total: number
          total: number
          montant_paye: number
          notes: string | null
          justificatif_url: string | null
          document_id: string | null
          livreur_nom: string | null
          livreur_telephone: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          numero: string
          canal?: Database['public']['Enums']['canal_vente']
          client_id?: string | null
          compte_client_id?: string | null
          nom_client: string
          telephone: string
          adresse?: string | null
          ville?: string | null
          zone_id?: string | null
          mode_livraison?: Database['public']['Enums']['mode_livraison']
          frais_livraison?: number
          statut?: Database['public']['Enums']['statut_commande']
          statut_paiement?: Database['public']['Enums']['statut_paiement_commande']
          mode_paiement?: Database['public']['Enums']['mode_paiement_commande']
          sous_total: number
          total: number
          montant_paye?: number
          notes?: string | null
          justificatif_url?: string | null
          document_id?: string | null
          livreur_nom?: string | null
          livreur_telephone?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          numero?: string
          canal?: Database['public']['Enums']['canal_vente']
          client_id?: string | null
          compte_client_id?: string | null
          nom_client?: string
          telephone?: string
          adresse?: string | null
          ville?: string | null
          zone_id?: string | null
          mode_livraison?: Database['public']['Enums']['mode_livraison']
          frais_livraison?: number
          statut?: Database['public']['Enums']['statut_commande']
          statut_paiement?: Database['public']['Enums']['statut_paiement_commande']
          mode_paiement?: Database['public']['Enums']['mode_paiement_commande']
          sous_total?: number
          total?: number
          montant_paye?: number
          notes?: string | null
          justificatif_url?: string | null
          document_id?: string | null
          livreur_nom?: string | null
          livreur_telephone?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        commercantes: {
        Row: {
          id: string
          utilisateur_id: string
          nom_ar: string | null
          nom_fr: string | null
          telephone: string
          whatsapp: string | null
          email: string | null
          ville: string | null
          notes: string | null
          statut: Database['public']['Enums']['statut_commercante']
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          utilisateur_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone: string
          whatsapp?: string | null
          email?: string | null
          ville?: string | null
          notes?: string | null
          statut?: Database['public']['Enums']['statut_commercante']
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          utilisateur_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string
          whatsapp?: string | null
          email?: string | null
          ville?: string | null
          notes?: string | null
          statut?: Database['public']['Enums']['statut_commercante']
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        comptes_clientes_site: {
        Row: {
          id: string
          boutique_id: string
          utilisateur_id: string
          nom: string
          telephone: string
          adresses: Json
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          utilisateur_id: string
          nom: string
          telephone: string
          adresses?: Json
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          utilisateur_id?: string
          nom?: string
          telephone?: string
          adresses?: Json
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        couleurs: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          code_hex: string
          ordre: number
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          code_hex: string
          ordre?: number
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          code_hex?: string
          ordre?: number
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        depenses: {
        Row: {
          id: string
          boutique_id: string
          categorie_id: string | null
          montant: number
          date_depense: string
          motif: string | null
          mode_paiement_id: string | null
          utilisateur_id: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          categorie_id?: string | null
          montant: number
          date_depense?: string
          motif?: string | null
          mode_paiement_id?: string | null
          utilisateur_id?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          categorie_id?: string | null
          montant?: number
          date_depense?: string
          motif?: string | null
          mode_paiement_id?: string | null
          utilisateur_id?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        documents_liens: {
        Row: {
          boutique_id: string
          document_id: string
          source_id: string
        }
        Insert: {
          boutique_id: string
          document_id: string
          source_id: string
        }
        Update: {
          boutique_id?: string
          document_id?: string
          source_id?: string
        }
        Relationships: []
        }
        documents_vente: {
        Row: {
          id: string
          boutique_id: string
          type: Database['public']['Enums']['type_document_vente']
          numero: string
          statut: Database['public']['Enums']['statut_document_vente']
          client_id: string | null
          document_source_id: string | null
          session_caisse_id: string | null
          canal: Database['public']['Enums']['canal_vente']
          date_emission: string
          date_echeance: string | null
          sous_total: number
          remise: number
          total: number
          paye: number
          reste: number | null
          notes: string | null
          entete: Json
          utilisateur_id: string | null
          annule_le: string | null
          motif_annulation: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          type: Database['public']['Enums']['type_document_vente']
          numero: string
          statut: Database['public']['Enums']['statut_document_vente']
          client_id?: string | null
          document_source_id?: string | null
          session_caisse_id?: string | null
          canal?: Database['public']['Enums']['canal_vente']
          date_emission?: string
          date_echeance?: string | null
          sous_total: number
          remise?: number
          total: number
          paye?: number
          reste?: number | null
          notes?: string | null
          entete: Json
          utilisateur_id?: string | null
          annule_le?: string | null
          motif_annulation?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          type?: Database['public']['Enums']['type_document_vente']
          numero?: string
          statut?: Database['public']['Enums']['statut_document_vente']
          client_id?: string | null
          document_source_id?: string | null
          session_caisse_id?: string | null
          canal?: Database['public']['Enums']['canal_vente']
          date_emission?: string
          date_echeance?: string | null
          sous_total?: number
          remise?: number
          total?: number
          paye?: number
          reste?: number | null
          notes?: string | null
          entete?: Json
          utilisateur_id?: string | null
          annule_le?: string | null
          motif_annulation?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        domaines_boutique: {
        Row: {
          id: string
          boutique_id: string
          sous_domaine: string
          domaine_personnalise: string | null
          statut_dns: Database['public']['Enums']['statut_domaine']
          statut_ssl: Database['public']['Enums']['statut_domaine']
          principal: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          sous_domaine: string
          domaine_personnalise?: string | null
          statut_dns?: Database['public']['Enums']['statut_domaine']
          statut_ssl?: Database['public']['Enums']['statut_domaine']
          principal?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          sous_domaine?: string
          domaine_personnalise?: string | null
          statut_dns?: Database['public']['Enums']['statut_domaine']
          statut_ssl?: Database['public']['Enums']['statut_domaine']
          principal?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        fournisseurs: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          telephone: string | null
          adresse: string | null
          solde: number
          notes: string | null
          cree_par: string | null
          cree_le: string
          modifie_le: string
          supprime_le: string | null
          boutique_liee_id: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          adresse?: string | null
          solde?: number
          notes?: string | null
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
          boutique_liee_id?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          adresse?: string | null
          solde?: number
          notes?: string | null
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
          boutique_liee_id?: string | null
        }
        Relationships: []
        }
        historique_statuts_commande: {
        Row: {
          id: string
          boutique_id: string
          commande_id: string
          statut: Database['public']['Enums']['statut_commande']
          utilisateur_id: string | null
          date_statut: string
          note: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          commande_id: string
          statut: Database['public']['Enums']['statut_commande']
          utilisateur_id?: string | null
          date_statut?: string
          note?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          commande_id?: string
          statut?: Database['public']['Enums']['statut_commande']
          utilisateur_id?: string | null
          date_statut?: string
          note?: string | null
        }
        Relationships: []
        }
        images_produit: {
        Row: {
          id: string
          boutique_id: string
          produit_id: string
          variante_id: string | null
          url: string
          principale: boolean
          ordre: number
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          produit_id: string
          variante_id?: string | null
          url: string
          principale?: boolean
          ordre?: number
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          produit_id?: string
          variante_id?: string | null
          url?: string
          principale?: boolean
          ordre?: number
          cree_le?: string
        }
        Relationships: []
        }
        journal_audit: {
        Row: {
          id: string
          boutique_id: string | null
          utilisateur_id: string | null
          action: string
          entite: string
          entite_id: string | null
          avant: Json | null
          apres: Json | null
          details: Json | null
          date_action: string
        }
        Insert: {
          id?: string
          boutique_id?: string | null
          utilisateur_id?: string | null
          action: string
          entite: string
          entite_id?: string | null
          avant?: Json | null
          apres?: Json | null
          details?: Json | null
          date_action?: string
        }
        Update: {
          id?: string
          boutique_id?: string | null
          utilisateur_id?: string | null
          action?: string
          entite?: string
          entite_id?: string | null
          avant?: Json | null
          apres?: Json | null
          details?: Json | null
          date_action?: string
        }
        Relationships: []
        }
        lignes_ajustement_stock: {
        Row: {
          id: string
          boutique_id: string
          ajustement_id: string
          variante_id: string
          quantite_systeme: number
          quantite_comptee: number | null
          ecart: number
        }
        Insert: {
          id?: string
          boutique_id: string
          ajustement_id: string
          variante_id: string
          quantite_systeme: number
          quantite_comptee?: number | null
          ecart: number
        }
        Update: {
          id?: string
          boutique_id?: string
          ajustement_id?: string
          variante_id?: string
          quantite_systeme?: number
          quantite_comptee?: number | null
          ecart?: number
        }
        Relationships: []
        }
        lignes_commande: {
        Row: {
          id: string
          boutique_id: string
          commande_id: string
          variante_id: string
          quantite: number
          prix_unitaire: number
          libelle_ar: string | null
          libelle_fr: string | null
          total: number
        }
        Insert: {
          id?: string
          boutique_id: string
          commande_id: string
          variante_id: string
          quantite: number
          prix_unitaire: number
          libelle_ar?: string | null
          libelle_fr?: string | null
          total: number
        }
        Update: {
          id?: string
          boutique_id?: string
          commande_id?: string
          variante_id?: string
          quantite?: number
          prix_unitaire?: number
          libelle_ar?: string | null
          libelle_fr?: string | null
          total?: number
        }
        Relationships: []
        }
        lignes_document_vente: {
        Row: {
          id: string
          boutique_id: string
          document_id: string
          variante_id: string | null
          libelle_ar: string | null
          libelle_fr: string | null
          quantite: number
          prix_unitaire: number
          remise: number
          cout_unitaire: number
          total: number
          ordre: number
          ligne_source_id: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          document_id: string
          variante_id?: string | null
          libelle_ar?: string | null
          libelle_fr?: string | null
          quantite: number
          prix_unitaire: number
          remise?: number
          cout_unitaire?: number
          total: number
          ordre?: number
          ligne_source_id?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          document_id?: string
          variante_id?: string | null
          libelle_ar?: string | null
          libelle_fr?: string | null
          quantite?: number
          prix_unitaire?: number
          remise?: number
          cout_unitaire?: number
          total?: number
          ordre?: number
          ligne_source_id?: string | null
        }
        Relationships: []
        }
        lignes_reception_stock: {
        Row: {
          id: string
          boutique_id: string
          reception_id: string
          variante_id: string
          quantite: number
          cout_unitaire: number
          date_expiration: string | null
          prix_vente: number | null
        }
        Insert: {
          id?: string
          boutique_id: string
          reception_id: string
          variante_id: string
          quantite: number
          cout_unitaire: number
          date_expiration?: string | null
          prix_vente?: number | null
        }
        Update: {
          id?: string
          boutique_id?: string
          reception_id?: string
          variante_id?: string
          quantite?: number
          cout_unitaire?: number
          date_expiration?: string | null
          prix_vente?: number | null
        }
        Relationships: []
        }
        lignes_transfert: {
        Row: {
          id: string
          transfert_id: string
          variante_emettrice_id: string
          variante_destinataire_id: string | null
          libelle_ar: string | null
          libelle_fr: string | null
          quantite: number
          prix_unitaire: number
          total: number
          ordre: number
        }
        Insert: {
          id?: string
          transfert_id: string
          variante_emettrice_id: string
          variante_destinataire_id?: string | null
          libelle_ar?: string | null
          libelle_fr?: string | null
          quantite: number
          prix_unitaire: number
          total: number
          ordre?: number
        }
        Update: {
          id?: string
          transfert_id?: string
          variante_emettrice_id?: string
          variante_destinataire_id?: string | null
          libelle_ar?: string | null
          libelle_fr?: string | null
          quantite?: number
          prix_unitaire?: number
          total?: number
          ordre?: number
        }
        Relationships: []
        }
        limites_debit: {
        Row: {
          cle: string
          compteur: number
          fenetre_debut: string
        }
        Insert: {
          cle: string
          compteur?: number
          fenetre_debut?: string
        }
        Update: {
          cle?: string
          compteur?: number
          fenetre_debut?: string
        }
        Relationships: []
        }
        lots_stock: {
        Row: {
          id: string
          boutique_id: string
          variante_id: string
          numero_lot: string
          recu_le: string
          quantite_initiale: number
          quantite_restante: number
          cout_unitaire: number
          date_expiration: string | null
          ligne_reception_id: string | null
          fournisseur_id: string | null
          decouvert: boolean
        }
        Insert: {
          id?: string
          boutique_id: string
          variante_id: string
          numero_lot: string
          recu_le?: string
          quantite_initiale: number
          quantite_restante: number
          cout_unitaire?: number
          date_expiration?: string | null
          ligne_reception_id?: string | null
          fournisseur_id?: string | null
          decouvert?: boolean
        }
        Update: {
          id?: string
          boutique_id?: string
          variante_id?: string
          numero_lot?: string
          recu_le?: string
          quantite_initiale?: number
          quantite_restante?: number
          cout_unitaire?: number
          date_expiration?: string | null
          ligne_reception_id?: string | null
          fournisseur_id?: string | null
          decouvert?: boolean
        }
        Relationships: []
        }
        marques: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          logo_url: string | null
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          logo_url?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          logo_url?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        membres_boutique: {
        Row: {
          id: string
          boutique_id: string
          utilisateur_id: string
          role_id: string
          statut: Database['public']['Enums']['statut_membre']
          invite_le: string
          invite_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          utilisateur_id: string
          role_id: string
          statut?: Database['public']['Enums']['statut_membre']
          invite_le?: string
          invite_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          utilisateur_id?: string
          role_id?: string
          statut?: Database['public']['Enums']['statut_membre']
          invite_le?: string
          invite_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        modeles: {
        Row: {
          id: string
          boutique_id: string
          categorie_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          categorie_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          categorie_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        modes_paiement: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          type: Database['public']['Enums']['type_mode_paiement']
          icone: string | null
          par_defaut: boolean
          actif: boolean
          ordre: number
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          type: Database['public']['Enums']['type_mode_paiement']
          icone?: string | null
          par_defaut?: boolean
          actif?: boolean
          ordre?: number
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          type?: Database['public']['Enums']['type_mode_paiement']
          icone?: string | null
          par_defaut?: boolean
          actif?: boolean
          ordre?: number
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        motifs_mouvement: {
        Row: {
          id: string
          boutique_id: string
          code: string | null
          nom_ar: string | null
          nom_fr: string | null
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          code?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          code?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        mouvements_stock: {
        Row: {
          id: string
          boutique_id: string
          variante_id: string
          lot_id: string | null
          type: Database['public']['Enums']['type_mouvement_stock']
          quantite: number
          cout_unitaire: number | null
          source_type: string | null
          source_id: string | null
          motif_id: string | null
          note: string | null
          utilisateur_id: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          variante_id: string
          lot_id?: string | null
          type: Database['public']['Enums']['type_mouvement_stock']
          quantite: number
          cout_unitaire?: number | null
          source_type?: string | null
          source_id?: string | null
          motif_id?: string | null
          note?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          variante_id?: string
          lot_id?: string | null
          type?: Database['public']['Enums']['type_mouvement_stock']
          quantite?: number
          cout_unitaire?: number | null
          source_type?: string | null
          source_id?: string | null
          motif_id?: string | null
          note?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        notifications: {
        Row: {
          id: string
          boutique_id: string | null
          utilisateur_id: string
          type: string
          titre_ar: string | null
          titre_fr: string | null
          corps_ar: string | null
          corps_fr: string | null
          cible: string
          donnees: Json
          lu_le: string | null
          cree_par: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id?: string | null
          utilisateur_id: string
          type?: string
          titre_ar?: string | null
          titre_fr?: string | null
          corps_ar?: string | null
          corps_fr?: string | null
          cible?: string
          donnees?: Json
          lu_le?: string | null
          cree_par?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string | null
          utilisateur_id?: string
          type?: string
          titre_ar?: string | null
          titre_fr?: string | null
          corps_ar?: string | null
          corps_fr?: string | null
          cible?: string
          donnees?: Json
          lu_le?: string | null
          cree_par?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        pages_site: {
        Row: {
          id: string
          boutique_id: string
          slug: string
          titre_ar: string | null
          titre_fr: string | null
          contenu_ar: string | null
          contenu_fr: string | null
          ordre: number
          visible: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          slug: string
          titre_ar?: string | null
          titre_fr?: string | null
          contenu_ar?: string | null
          contenu_fr?: string | null
          ordre?: number
          visible?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          slug?: string
          titre_ar?: string | null
          titre_fr?: string | null
          contenu_ar?: string | null
          contenu_fr?: string | null
          ordre?: number
          visible?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        paiements: {
        Row: {
          id: string
          boutique_id: string
          document_id: string | null
          client_id: string | null
          mode_paiement_id: string
          montant: number
          paye_le: string
          session_caisse_id: string | null
          reference: string | null
          justificatif_url: string | null
          utilisateur_id: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          document_id?: string | null
          client_id?: string | null
          mode_paiement_id: string
          montant: number
          paye_le?: string
          session_caisse_id?: string | null
          reference?: string | null
          justificatif_url?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          document_id?: string | null
          client_id?: string | null
          mode_paiement_id?: string
          montant?: number
          paye_le?: string
          session_caisse_id?: string | null
          reference?: string | null
          justificatif_url?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        paiements_abonnement: {
        Row: {
          id: string
          abonnement_id: string
          boutique_id: string
          montant: number
          devise: string
          mode: Database['public']['Enums']['mode_paiement_abonnement']
          reference: string | null
          justificatif_url: string | null
          paye_le: string
          periode_mois: number
          enregistre_par: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          abonnement_id: string
          boutique_id: string
          montant: number
          devise?: string
          mode: Database['public']['Enums']['mode_paiement_abonnement']
          reference?: string | null
          justificatif_url?: string | null
          paye_le?: string
          periode_mois?: number
          enregistre_par?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          abonnement_id?: string
          boutique_id?: string
          montant?: number
          devise?: string
          mode?: Database['public']['Enums']['mode_paiement_abonnement']
          reference?: string | null
          justificatif_url?: string | null
          paye_le?: string
          periode_mois?: number
          enregistre_par?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        parametres_site: {
        Row: {
          boutique_id: string
          theme_id: string | null
          config_theme: Json
          config_brouillon: Json | null
          logo_url: string | null
          favicon_url: string | null
          liens_sociaux: Json
          referencement: Json
          infos_paiement: Json
          horaires: Json
          commande_minimale: number
          livraison_active: boolean
          retrait_boutique_actif: boolean
          paiement_livraison_actif: boolean
          mobile_money_actif: boolean
          afficher_stock: boolean
          masquer_epuises: boolean
          message_confirmation_ar: string | null
          message_confirmation_fr: string | null
          langues_activees: string[]
          publie: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          boutique_id: string
          theme_id?: string | null
          config_theme?: Json
          config_brouillon?: Json | null
          logo_url?: string | null
          favicon_url?: string | null
          liens_sociaux?: Json
          referencement?: Json
          infos_paiement?: Json
          horaires?: Json
          commande_minimale?: number
          livraison_active?: boolean
          retrait_boutique_actif?: boolean
          paiement_livraison_actif?: boolean
          mobile_money_actif?: boolean
          afficher_stock?: boolean
          masquer_epuises?: boolean
          message_confirmation_ar?: string | null
          message_confirmation_fr?: string | null
          langues_activees?: string[]
          publie?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          boutique_id?: string
          theme_id?: string | null
          config_theme?: Json
          config_brouillon?: Json | null
          logo_url?: string | null
          favicon_url?: string | null
          liens_sociaux?: Json
          referencement?: Json
          infos_paiement?: Json
          horaires?: Json
          commande_minimale?: number
          livraison_active?: boolean
          retrait_boutique_actif?: boolean
          paiement_livraison_actif?: boolean
          mobile_money_actif?: boolean
          afficher_stock?: boolean
          masquer_epuises?: boolean
          message_confirmation_ar?: string | null
          message_confirmation_fr?: string | null
          langues_activees?: string[]
          publie?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        permissions: {
        Row: {
          cle: string
          module: string
          nom_ar: string
          nom_fr: string
        }
        Insert: {
          cle: string
          module: string
          nom_ar: string
          nom_fr: string
        }
        Update: {
          cle?: string
          module?: string
          nom_ar?: string
          nom_fr?: string
        }
        Relationships: []
        }
        permissions_role: {
        Row: {
          role_id: string
          cle_permission: string
          autorise: boolean
        }
        Insert: {
          role_id: string
          cle_permission: string
          autorise?: boolean
        }
        Update: {
          role_id?: string
          cle_permission?: string
          autorise?: boolean
        }
        Relationships: []
        }
        plages_numeros: {
        Row: {
          id: string
          boutique_id: string
          type_document: string
          annee: number
          appareil_id: string
          debut: number
          fin: number
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          type_document: string
          annee: number
          appareil_id: string
          debut: number
          fin: number
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          type_document?: string
          annee?: number
          appareil_id?: string
          debut?: number
          fin?: number
          cree_le?: string
        }
        Relationships: []
        }
        plans: {
        Row: {
          id: string
          code: string
          nom_ar: string
          nom_fr: string
          description_ar: string | null
          description_fr: string | null
          prix_mensuel: number
          prix_annuel: number
          devise: string
          limites: Json
          duree_essai_jours: number | null
          ordre: number
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          code: string
          nom_ar: string
          nom_fr: string
          description_ar?: string | null
          description_fr?: string | null
          prix_mensuel?: number
          prix_annuel?: number
          devise?: string
          limites?: Json
          duree_essai_jours?: number | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          code?: string
          nom_ar?: string
          nom_fr?: string
          description_ar?: string | null
          description_fr?: string | null
          prix_mensuel?: number
          prix_annuel?: number
          devise?: string
          limites?: Json
          duree_essai_jours?: number | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        produits: {
        Row: {
          id: string
          boutique_id: string
          categorie_id: string | null
          marque_id: string | null
          unite_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          description_ar: string | null
          description_fr: string | null
          slug: string | null
          statut: Database['public']['Enums']['statut_produit']
          visible_en_ligne: boolean
          epingle: boolean
          ordre_epinglage: number | null
          ordre: number
          etiquettes: string[]
          cree_par: string | null
          cree_le: string
          modifie_le: string
          supprime_le: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          categorie_id?: string | null
          marque_id?: string | null
          unite_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          description_ar?: string | null
          description_fr?: string | null
          slug?: string | null
          statut?: Database['public']['Enums']['statut_produit']
          visible_en_ligne?: boolean
          epingle?: boolean
          ordre_epinglage?: number | null
          ordre?: number
          etiquettes?: string[]
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          categorie_id?: string | null
          marque_id?: string | null
          unite_id?: string | null
          nom_ar?: string | null
          nom_fr?: string | null
          description_ar?: string | null
          description_fr?: string | null
          slug?: string | null
          statut?: Database['public']['Enums']['statut_produit']
          visible_en_ligne?: boolean
          epingle?: boolean
          ordre_epinglage?: number | null
          ordre?: number
          etiquettes?: string[]
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
        }
        Relationships: []
        }
        profils: {
        Row: {
          id: string
          nom_ar: string | null
          nom_fr: string | null
          telephone: string | null
          email: string | null
          role_plateforme: Database['public']['Enums']['role_plateforme']
          langue: string
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          email?: string | null
          role_plateforme?: Database['public']['Enums']['role_plateforme']
          langue?: string
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          telephone?: string | null
          email?: string | null
          role_plateforme?: Database['public']['Enums']['role_plateforme']
          langue?: string
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        receptions_stock: {
        Row: {
          id: string
          boutique_id: string
          fournisseur_id: string | null
          transfert_id: string | null
          date_reception: string
          reference: string | null
          total: number
          montant_paye: number
          notes: string | null
          utilisateur_id: string | null
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          fournisseur_id?: string | null
          transfert_id?: string | null
          date_reception?: string
          reference?: string | null
          total?: number
          montant_paye?: number
          notes?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          fournisseur_id?: string | null
          transfert_id?: string | null
          date_reception?: string
          reference?: string | null
          total?: number
          montant_paye?: number
          notes?: string | null
          utilisateur_id?: string | null
          cree_le?: string
        }
        Relationships: []
        }
        roles: {
        Row: {
          id: string
          boutique_id: string | null
          cle: string
          nom_ar: string
          nom_fr: string
          systeme: boolean
          cree_le: string
        }
        Insert: {
          id?: string
          boutique_id?: string | null
          cle: string
          nom_ar: string
          nom_fr: string
          systeme?: boolean
          cree_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string | null
          cle?: string
          nom_ar?: string
          nom_fr?: string
          systeme?: boolean
          cree_le?: string
        }
        Relationships: []
        }
        sections_site: {
        Row: {
          id: string
          boutique_id: string
          type: string
          titre_ar: string | null
          titre_fr: string | null
          contenu_ar: string | null
          contenu_fr: string | null
          config: Json
          ordre: number
          visible: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          type: string
          titre_ar?: string | null
          titre_fr?: string | null
          contenu_ar?: string | null
          contenu_fr?: string | null
          config?: Json
          ordre?: number
          visible?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          type?: string
          titre_ar?: string | null
          titre_fr?: string | null
          contenu_ar?: string | null
          contenu_fr?: string | null
          config?: Json
          ordre?: number
          visible?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        sequences_documents: {
        Row: {
          boutique_id: string
          type_document: string
          annee: number
          prochain_numero: number
          prefixe: string | null
        }
        Insert: {
          boutique_id: string
          type_document: string
          annee?: number
          prochain_numero?: number
          prefixe?: string | null
        }
        Update: {
          boutique_id?: string
          type_document?: string
          annee?: number
          prochain_numero?: number
          prefixe?: string | null
        }
        Relationships: []
        }
        sessions_caisse: {
        Row: {
          id: string
          boutique_id: string
          utilisateur_id: string
          appareil_id: string | null
          ouverte_le: string
          fermee_le: string | null
          fond_initial: number
          attendu: number | null
          compte: number | null
          ecart: number | null
          notes: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          utilisateur_id: string
          appareil_id?: string | null
          ouverte_le?: string
          fermee_le?: string | null
          fond_initial?: number
          attendu?: number | null
          compte?: number | null
          ecart?: number | null
          notes?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          utilisateur_id?: string
          appareil_id?: string | null
          ouverte_le?: string
          fermee_le?: string | null
          fond_initial?: number
          attendu?: number | null
          compte?: number | null
          ecart?: number | null
          notes?: string | null
        }
        Relationships: []
        }
        tailles: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          type: string
          ordre: number
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          type?: string
          ordre?: number
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          type?: string
          ordre?: number
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        tentatives_connexion: {
        Row: {
          identifiant: string
          echecs: number
          verrouille_jusqu_au: string | null
          derniere_tentative_le: string
        }
        Insert: {
          identifiant: string
          echecs?: number
          verrouille_jusqu_au?: string | null
          derniere_tentative_le?: string
        }
        Update: {
          identifiant?: string
          echecs?: number
          verrouille_jusqu_au?: string | null
          derniere_tentative_le?: string
        }
        Relationships: []
        }
        themes_site: {
        Row: {
          id: string
          code: string
          nom_ar: string
          nom_fr: string
          apercu_url: string | null
          schema_config: Json
          plan_minimum: number
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          code: string
          nom_ar: string
          nom_fr: string
          apercu_url?: string | null
          schema_config?: Json
          plan_minimum?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          code?: string
          nom_ar?: string
          nom_fr?: string
          apercu_url?: string | null
          schema_config?: Json
          plan_minimum?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        transferts: {
        Row: {
          id: string
          numero: string
          boutique_emettrice_id: string
          boutique_destinataire_id: string
          statut: Database['public']['Enums']['statut_transfert']
          note: string | null
          total: number
          envoye_par: string | null
          repondu_par: string | null
          reception_id: string | null
          cree_le: string
          repondu_le: string | null
        }
        Insert: {
          id?: string
          numero: string
          boutique_emettrice_id: string
          boutique_destinataire_id: string
          statut?: Database['public']['Enums']['statut_transfert']
          note?: string | null
          total?: number
          envoye_par?: string | null
          repondu_par?: string | null
          reception_id?: string | null
          cree_le?: string
          repondu_le?: string | null
        }
        Update: {
          id?: string
          numero?: string
          boutique_emettrice_id?: string
          boutique_destinataire_id?: string
          statut?: Database['public']['Enums']['statut_transfert']
          note?: string | null
          total?: number
          envoye_par?: string | null
          repondu_par?: string | null
          reception_id?: string | null
          cree_le?: string
          repondu_le?: string | null
        }
        Relationships: []
        }
        unites: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          abreviation: string | null
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          abreviation?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          abreviation?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
        variantes_produit: {
        Row: {
          id: string
          boutique_id: string
          produit_id: string
          modele_id: string | null
          couleur_id: string | null
          taille_id: string | null
          sku: string | null
          code_barres: string | null
          prix_vente: number
          prix_gros: number | null
          prix_promo: number | null
          promo_debut: string | null
          promo_fin: string | null
          stock_minimum: number
          image_url: string | null
          actif: boolean
          cree_par: string | null
          cree_le: string
          modifie_le: string
          supprime_le: string | null
        }
        Insert: {
          id?: string
          boutique_id: string
          produit_id: string
          modele_id?: string | null
          couleur_id?: string | null
          taille_id?: string | null
          sku?: string | null
          code_barres?: string | null
          prix_vente: number
          prix_gros?: number | null
          prix_promo?: number | null
          promo_debut?: string | null
          promo_fin?: string | null
          stock_minimum?: number
          image_url?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
        }
        Update: {
          id?: string
          boutique_id?: string
          produit_id?: string
          modele_id?: string | null
          couleur_id?: string | null
          taille_id?: string | null
          sku?: string | null
          code_barres?: string | null
          prix_vente?: number
          prix_gros?: number | null
          prix_promo?: number | null
          promo_debut?: string | null
          promo_fin?: string | null
          stock_minimum?: number
          image_url?: string | null
          actif?: boolean
          cree_par?: string | null
          cree_le?: string
          modifie_le?: string
          supprime_le?: string | null
        }
        Relationships: []
        }
        zones_livraison: {
        Row: {
          id: string
          boutique_id: string
          nom_ar: string | null
          nom_fr: string | null
          frais: number
          delai_jours: number | null
          ordre: number
          actif: boolean
          cree_le: string
          modifie_le: string
        }
        Insert: {
          id?: string
          boutique_id: string
          nom_ar?: string | null
          nom_fr?: string | null
          frais?: number
          delai_jours?: number | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Update: {
          id?: string
          boutique_id?: string
          nom_ar?: string | null
          nom_fr?: string | null
          frais?: number
          delai_jours?: number | null
          ordre?: number
          actif?: boolean
          cree_le?: string
          modifie_le?: string
        }
        Relationships: []
        }
    }
    Views: {
        bannieres_site_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          image_url: string | null
          titre_ar: string | null
          titre_fr: string | null
          lien: string | null
          ordre: number | null
        }
        Relationships: []
        }
        categories_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          parent_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          image_url: string | null
          ordre: number | null
          icone: string | null
        }
        Relationships: []
        }
        couleurs_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          code_hex: string | null
          ordre: number | null
        }
        Relationships: []
        }
        images_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          produit_id: string | null
          variante_id: string | null
          url: string | null
          principale: boolean | null
          ordre: number | null
        }
        Relationships: []
        }
        lignes_document_vente_vue: {
        Row: {
          id: string | null
          boutique_id: string | null
          document_id: string | null
          variante_id: string | null
          libelle_ar: string | null
          libelle_fr: string | null
          quantite: number | null
          prix_unitaire: number | null
          remise: number | null
          total: number | null
          ordre: number | null
          cout_unitaire: number | null
          ligne_source_id: string | null
        }
        Relationships: []
        }
        lignes_reception_stock_vue: {
        Row: {
          id: string | null
          boutique_id: string | null
          reception_id: string | null
          variante_id: string | null
          quantite: number | null
          date_expiration: string | null
          prix_vente: number | null
          cout_unitaire: number | null
        }
        Relationships: []
        }
        lots_stock_vue: {
        Row: {
          id: string | null
          boutique_id: string | null
          variante_id: string | null
          numero_lot: string | null
          recu_le: string | null
          quantite_initiale: number | null
          quantite_restante: number | null
          cout_unitaire: number | null
          date_expiration: string | null
          ligne_reception_id: string | null
          fournisseur_id: string | null
          decouvert: boolean | null
        }
        Relationships: []
        }
        modeles_publics: {
        Row: {
          id: string | null
          boutique_id: string | null
          categorie_id: string | null
          nom_ar: string | null
          nom_fr: string | null
        }
        Relationships: []
        }
        mouvements_stock_vue: {
        Row: {
          id: string | null
          boutique_id: string | null
          variante_id: string | null
          lot_id: string | null
          type: Database['public']['Enums']['type_mouvement_stock'] | null
          quantite: number | null
          cout_unitaire: number | null
          source_type: string | null
          source_id: string | null
          motif_id: string | null
          note: string | null
          utilisateur_id: string | null
          cree_le: string | null
        }
        Relationships: []
        }
        pages_site_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          slug: string | null
          titre_ar: string | null
          titre_fr: string | null
          contenu_ar: string | null
          contenu_fr: string | null
          ordre: number | null
        }
        Relationships: []
        }
        parametres_boutique_publics: {
        Row: {
          boutique_id: string | null
          slug: string | null
          nom_ar: string | null
          nom_fr: string | null
          logo_url: string | null
          devise: string | null
          langue_par_defaut: string | null
          telephone: string | null
          whatsapp: string | null
          adresse: string | null
          ville: string | null
          theme_id: string | null
          theme_code: string | null
          config_theme: Json | null
          favicon_url: string | null
          liens_sociaux: Json | null
          referencement: Json | null
          infos_paiement: Json | null
          horaires: Json | null
          commande_minimale: number | null
          livraison_active: boolean | null
          retrait_boutique_actif: boolean | null
          paiement_livraison_actif: boolean | null
          mobile_money_actif: boolean | null
          afficher_stock: boolean | null
          masquer_epuises: boolean | null
          message_confirmation_ar: string | null
          message_confirmation_fr: string | null
          langues_activees: string[] | null
          theme_schema: Json | null
        }
        Relationships: []
        }
        produits_publics: {
        Row: {
          id: string | null
          boutique_id: string | null
          slug: string | null
          nom_ar: string | null
          nom_fr: string | null
          description_ar: string | null
          description_fr: string | null
          categorie_id: string | null
          categorie_ordre: number | null
          marque_id: string | null
          epingle: boolean | null
          ordre_epinglage: number | null
          ordre: number | null
          etiquettes: string[] | null
          cree_le: string | null
          prix_min: number | null
          prix_normal_min: number | null
          en_promo: boolean | null
          epuise: boolean | null
          image_url: string | null
        }
        Relationships: []
        }
        receptions_stock_vue: {
        Row: {
          id: string | null
          boutique_id: string | null
          fournisseur_id: string | null
          transfert_id: string | null
          date_reception: string | null
          reference: string | null
          notes: string | null
          utilisateur_id: string | null
          cree_le: string | null
          total: number | null
          montant_paye: number | null
        }
        Relationships: []
        }
        sections_site_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          type: string | null
          titre_ar: string | null
          titre_fr: string | null
          contenu_ar: string | null
          contenu_fr: string | null
          config: Json | null
          ordre: number | null
        }
        Relationships: []
        }
        stock_variante: {
        Row: {
          variante_id: string | null
          boutique_id: string | null
          en_stock: number | null
          reserve: number | null
          disponible: number | null
        }
        Relationships: []
        }
        variantes_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          produit_id: string | null
          modele_id: string | null
          couleur_id: string | null
          taille_id: string | null
          prix: number | null
          prix_normal: number | null
          en_promo: boolean | null
          image_url: string | null
          modele_nom_ar: string | null
          modele_nom_fr: string | null
          couleur_nom_ar: string | null
          couleur_nom_fr: string | null
          couleur_hex: string | null
          taille_nom_ar: string | null
          taille_nom_fr: string | null
          epuisee: boolean | null
          stock_visible: number | null
        }
        Relationships: []
        }
        zones_livraison_publiques: {
        Row: {
          id: string | null
          boutique_id: string | null
          nom_ar: string | null
          nom_fr: string | null
          frais: number | null
          delai_jours: number | null
        }
        Relationships: []
        }
    }
    Functions: {
      admin_quotas_boutique: {
        Args: {
        p_boutique: string
      }
        Returns: Json
      }
      admin_statistiques: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      ajuster_stock: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      alertes_stock: {
        Args: {
        p_boutique: string
        p_jours?: number
      }
        Returns: Json
      }
      annuler_document: {
        Args: {
        p_id: string
        p_motif: string
      }
        Returns: Json
      }
      annuler_transfert: {
        Args: {
        p_id: string
      }
        Returns: Json
      }
      attribuer_numero_document: {
        Args: {
        p_boutique_id: string
        p_type: string
      }
        Returns: string
      }
      boutique_est_active: {
        Args: {
        p_boutique: string
      }
        Returns: boolean
      }
      changer_statut_bon_livraison: {
        Args: {
        p_id: string
        p_statut: Database['public']['Enums']['statut_document_vente']
      }
        Returns: Json
      }
      changer_statut_commande: {
        Args: {
        p_commande_id: string
        p_statut: Database['public']['Enums']['statut_commande']
        p_note?: string
      }
        Returns: Json
      }
      changer_statut_devis: {
        Args: {
        p_id: string
        p_statut: Database['public']['Enums']['statut_document_vente']
      }
        Returns: Json
      }
      convertir_document: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      creer_avoir: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      creer_bon_livraison: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      creer_boutique_avec_defauts: {
        Args: {
        p_commercante_id: string
        p_nom_ar: string
        p_nom_fr: string
        p_slug: string
        p_type_activite?: string
        p_telephone?: string
        p_devise?: string
        p_id?: string
      }
        Returns: string
      }
      creer_commercante_avec_boutique: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      creer_devis: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      detail_transfert: {
        Args: {
        p_boutique: string
        p_id: string
      }
        Returns: Json
      }
      ecarts_stock: {
        Args: {
        p_boutique: string
      }
        Returns: Json
      }
      enregistrer_client: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      enregistrer_depense: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      enregistrer_echec_connexion: {
        Args: {
        p_identifiant: string
        p_max?: number
        p_duree_secondes?: number
      }
        Returns: string
      }
      enregistrer_jeton_fcm: {
        Args: {
        p_appareil: string
        p_jeton: string
      }
        Returns: undefined
      }
      enregistrer_paiement: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      enregistrer_paiement_abonnement: {
        Args: {
        p_abonnement_id: string
        p_montant: number
        p_mode: Database['public']['Enums']['mode_paiement_abonnement']
        p_reference?: string
        p_justificatif_url?: string
        p_periode_mois?: number
        p_paye_le?: string
      }
        Returns: string
      }
      enregistrer_vente: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      envoyer_transfert: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      expirer_devis_perimes: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      fermer_session_caisse: {
        Args: {
        p_session_id: string
        p_compte: number
        p_notes?: string
      }
        Returns: Json
      }
      generer_alertes_impayes: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      generer_alertes_stock: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      generer_document_commande: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      inviter_membre: {
        Args: {
        p_donnees: Json
      }
        Returns: string
      }
      joindre_justificatif_commande: {
        Args: {
        p_slug: string
        p_commande_id: string
        p_telephone: string
        p_chemin: string
      }
        Returns: undefined
      }
      limiter_requete: {
        Args: {
        p_cle: string
        p_max: number
        p_fenetre_secondes: number
      }
        Returns: undefined
      }
      liste_transferts: {
        Args: {
        p_boutique: string
      }
        Returns: Json
      }
      mes_permissions: {
        Args: {
        p_boutique: string
      }
        Returns: string[]
      }
      modifier_devis: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      ouvrir_session_caisse: {
        Args: {
        p_boutique_id: string
        p_id: string
        p_fond?: number
        p_appareil_id?: string
      }
        Returns: Json
      }
      passer_commande_en_ligne: {
        Args: {
        p_slug: string
        p_donnees: Json
      }
        Returns: Json
      }
      rapport_impayes: {
        Args: {
        p_boutique: string
      }
        Returns: Json
      }
      rapport_produits: {
        Args: {
        p_boutique: string
        p_debut: string
        p_fin: string
        p_type: string
        p_limite?: number
      }
        Returns: Json
      }
      rapport_stock: {
        Args: {
        p_boutique: string
      }
        Returns: Json
      }
      rapport_synthese: {
        Args: {
        p_boutique: string
        p_debut: string
        p_fin: string
      }
        Returns: Json
      }
      rapport_ventes: {
        Args: {
        p_boutique: string
        p_debut: string
        p_fin: string
        p_axe: string
      }
        Returns: Json
      }
      recevoir_stock: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      reinitialiser_tentatives_connexion: {
        Args: {
        p_identifiant: string
      }
        Returns: undefined
      }
      repondre_transfert: {
        Args: {
        p_donnees: Json
      }
        Returns: Json
      }
      reserver_plage_numeros: {
        Args: {
        p_boutique_id: string
        p_type: string
        p_appareil_id: string
        p_taille?: number
      }
        Returns: Json
      }
      resoudre_boutique: {
        Args: {
        p_hote: string
      }
        Returns: Json
      }
      suivre_commande: {
        Args: {
        p_slug: string
        p_numero: string
        p_telephone: string
      }
        Returns: Json
      }
      suivre_commandes_par_telephone: {
        Args: {
        p_slug: string
        p_telephone: string
      }
        Returns: Json
      }
      tableau_de_bord: {
        Args: {
        p_boutique_id: string
      }
        Returns: Json
      }
      traiter_abonnements: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
      valider_ecart_stock: {
        Args: {
        p_boutique: string
        p_variante: string
      }
        Returns: Json
      }
      verifier_verrou_connexion: {
        Args: {
        p_identifiant: string
      }
        Returns: string
      }
    }
    Enums: {
      canal_vente: 'caisse' | 'site_web' | 'whatsapp' | 'instagram' | 'facebook' | 'telephone' | 'autre'
      mode_livraison: 'livraison' | 'retrait'
      mode_paiement_abonnement: 'especes' | 'virement' | 'mobile_money'
      mode_paiement_commande: 'a_la_livraison' | 'mobile_money' | 'especes' | 'autre'
      plateforme_appareil: 'android' | 'ios' | 'web'
      role_plateforme: 'super_admin' | 'support' | 'aucun'
      statut_abonnement: 'essai' | 'actif' | 'grace' | 'suspendu' | 'expire' | 'annule'
      statut_boutique: 'essai' | 'actif' | 'grace' | 'suspendu' | 'ferme'
      statut_commande: 'nouvelle' | 'confirmee' | 'en_preparation' | 'prete' | 'expediee' | 'livree' | 'annulee' | 'retournee'
      statut_commercante: 'active' | 'desactivee'
      statut_document_vente: 'brouillon' | 'envoye' | 'accepte' | 'refuse' | 'expire' | 'valide' | 'livre' | 'facture' | 'emise' | 'partiellement_payee' | 'payee' | 'annulee'
      statut_domaine: 'non_configure' | 'en_attente' | 'verifie' | 'erreur'
      statut_membre: 'invite' | 'actif' | 'desactive'
      statut_paiement_commande: 'non_paye' | 'partiel' | 'paye'
      statut_produit: 'actif' | 'inactif'
      statut_transfert: 'en_attente' | 'accepte' | 'refuse' | 'annule'
      type_ajustement_stock: 'sortie_manuelle' | 'inventaire' | 'retour_fournisseur'
      type_document_vente: 'devis' | 'bon_livraison' | 'facture' | 'avoir' | 'ticket'
      type_mode_paiement: 'especes' | 'mobile_money' | 'banque' | 'carte' | 'credit'
      type_mouvement_stock: 'entree' | 'sortie_vente' | 'sortie_manuelle' | 'retour_client' | 'retour_fournisseur' | 'ajustement' | 'reservation' | 'liberation' | 'transfert_sortie' | 'transfert_entree'
    }
    CompositeTypes: Record<string, never>
  }
}

type Public = Database['public']
export type Tables<T extends keyof Public['Tables']> = Public['Tables'][T]['Row']
export type TablesInsert<T extends keyof Public['Tables']> = Public['Tables'][T]['Insert']
export type TablesUpdate<T extends keyof Public['Tables']> = Public['Tables'][T]['Update']
export type Views<T extends keyof Public['Views']> = Public['Views'][T]['Row']
export type Enums<T extends keyof Public['Enums']> = Public['Enums'][T]
