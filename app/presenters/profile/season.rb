# frozen_string_literal: true

module Profile
  # Onglet « Ma saison » : licence, crédits, stats, argent.
  #
  # Aucune requête dans `initialize` : le contrôleur n'instancie que le
  # presenter de l'onglet affiché, et une méthode non appelée ne coûte rien.
  class Season
    CREDITS = "credits"
    PURCHASES = "purchases"

    def initialize(user:, page: nil, history: nil)
      @user = user
      @page = page
      @history = history.to_s
    end

    # Licence ------------------------------------------------------------

    def activated?
      user.activated?
    end

    def member_since_year
      user.created_at.year
    end

    # Crédits ------------------------------------------------------------

    def balance
      @balance ||= user.balance&.amount.to_i
    end

    # Stats --------------------------------------------------------------

    def stats
      @stats ||= Stats::PlayerStats.new(user: user).call
    end

    # Argent -------------------------------------------------------------

    # Sous-onglet de l'historique. « credits » par défaut.
    def history_tab
      @history_tab ||= history == PURCHASES ? PURCHASES : CREDITS
    end

    def credits_history?
      history_tab == CREDITS
    end

    def purchases_history?
      history_tab == PURCHASES
    end

    # L'ancienne page chargeait TOUTES les transactions, sans limite, et
    # rappelait `.count` dans la vue pour afficher le total.
    def transactions
      @transactions ||= Pagination.new(
        scope: user.credit_transactions.includes(:session).order(created_at: :desc),
        page: page
      )
    end

    # Les achats réels (montant en euros, pack, référence) n'étaient jamais
    # montrés au joueur : seule leur contrepartie en crédits apparaissait.
    def purchases
      @purchases ||= Pagination.new(
        scope: user.credit_purchases.includes(:pack).order(created_at: :desc),
        page: page
      )
    end

    def history_pagination
      credits_history? ? transactions : purchases
    end

    private

    attr_reader :user, :page, :history
  end
end
