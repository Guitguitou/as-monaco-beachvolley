# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    # Downloading a session's .ics is a read-only capability.
    alias_action :calendar, :preview, to: :read

    if user.admin?
      can :manage, :all
      return
    end

    # Droits sur son propre compte : posés AVANT les retours anticipés, sinon
    # un responsable financier n'a aucun droit sur lui-même et prend un 403
    # sur sa propre page de profil.
    if user.id.present? && !user.disabled?
      can [ :read, :update ], User, id: user.id
    end

    # Responsable financier : accès limité au dashboard et historique des achats
    if user.financial_manager?
      can :read, :admin_dashboard
      can :read, CreditPurchase
      return
    end

    # Base permissions for all authenticated users
    if user.id.present? && !user.disabled?
      # Sans Compte actif : accès limité aux licences, stages et infos. Une fois
      # la licence payée (dossier en attente), le pack licence disparaît pour
      # éviter un second paiement.
      if !user.compte_actif?
        pack_types = [ "stage", "inscription_tournoi", "equipements" ]
        pack_types << "licence" unless user.licence_payee?
        can :read, Pack, pack_type: pack_types
        can :buy, Pack, pack_type: pack_types
        can :read, Stage
        can :read, Tournament
        # Access to infos pages (handled in routes, no specific permission needed)
      else
        # Compte actif : accès complet
        can :read, Session
        can :read, Stage
        can :read, Tournament
        can :read, Pack  # Tous les packs
        can :buy, Pack   # Peut acheter tous les packs

        can :create, Registration
        can [ :destroy ], Registration, user_id: user.id

        # Annonces de jeu libre : lecture/création pour tout Compte actif,
        # gestion (édition, confirmation, annulation) réservée au créateur.
        can [ :read, :create ], Annonce
        can :toggle_availability, Annonce
        can [ :update, :destroy, :confirm, :cancel ], Annonce, user_id: user.id

        # View own credit history
        can :read, CreditTransaction, user_id: user.id
      end
    end

    # Elevated roles
    if (user.coach? || user.responsable?) && !user.disabled?
      # Give all CRUD actions except cancel
      can [ :read, :create, :update, :destroy ], Session
      # Can only cancel their own sessions
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end
