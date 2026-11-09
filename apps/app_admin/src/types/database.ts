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
    }
    Views: {

    }
    Functions: {
      boutique_est_active: {
        Args: {
        p_boutique: string
      }
        Returns: boolean
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
      enregistrer_echec_connexion: {
        Args: {
        p_identifiant: string
        p_max?: number
        p_duree_secondes?: number
      }
        Returns: string
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
      inviter_membre: {
        Args: {
        p_donnees: Json
      }
        Returns: string
      }
      mes_permissions: {
        Args: {
        p_boutique: string
      }
        Returns: string[]
      }
      reinitialiser_tentatives_connexion: {
        Args: {
        p_identifiant: string
      }
        Returns: undefined
      }
      verifier_verrou_connexion: {
        Args: {
        p_identifiant: string
      }
        Returns: string
      }
    }
    Enums: {
      mode_paiement_abonnement: 'especes' | 'virement' | 'mobile_money'
      plateforme_appareil: 'android' | 'ios' | 'web'
      role_plateforme: 'super_admin' | 'support' | 'aucun'
      statut_abonnement: 'essai' | 'actif' | 'grace' | 'suspendu' | 'expire' | 'annule'
      statut_boutique: 'essai' | 'actif' | 'grace' | 'suspendu' | 'ferme'
      statut_commercante: 'active' | 'desactivee'
      statut_membre: 'invite' | 'actif' | 'desactive'
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
