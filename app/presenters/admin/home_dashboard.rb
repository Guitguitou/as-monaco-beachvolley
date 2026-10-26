# frozen_string_literal: true

module Admin
  # Dashboard d'accueil de l'admin : ce qu'il faut faire aujourd'hui.
  # Les chiffres de la semaine (avec leur tendance), les actions en attente
  # (chacune ouvre le tableau déjà filtré) et les séances à risque.
  class HomeDashboard
    Action = Data.define(:label, :count, :icon, :path)
    AtRisk = Data.define(:session, :confirmed, :fill_rate)

    AT_RISK_DAYS = 7
    AT_RISK_FILL = 40

    def initialize(routes:, now: Time.current)
      @routes = routes
      @now = now
    end

    def metrics = Reporting::WeekPulse.new(now: @now).metrics

    def actions
      [
        Action.new(label: "Dossiers à compléter (licence payée)", count: User.activated.where(dossier_complet: false).count,
                   icon: "file-warning", path: @routes.admin_users_path(f: { activated: "1", dossier_complet: "0" })),
        Action.new(label: "Licences non payées", count: User.not_activated.where(disabled_at: nil).count, icon: "badge-euro",
                   path: @routes.admin_users_path(f: { activated: "0" })),
        Action.new(label: "Paiements en attente", count: CreditPurchase.pending_status.count, icon: "clock",
                   path: @routes.admin_purchase_history_index_path(f: { status: [ "pending" ] })),
        Action.new(label: "Séances à remplir cette semaine", count: at_risk_sessions.size, icon: "triangle-alert",
                   path: @routes.admin_root_path(tab: "alerts"))
      ]
    end

    # Séances des prochains jours remplies à moins de 40 %, les plus vides d'abord.
    def at_risk_sessions
      @at_risk_sessions ||= begin
        sessions = Session.held.where(start_at: @now..(@now + AT_RISK_DAYS.days)).where.not(max_players: [ nil, 0 ])
                          .includes(:terrain, :user).to_a
        counts = Registration.confirmed.where(session_id: sessions.map(&:id)).group(:session_id).count
        sessions.filter_map { |session| at_risk(session, counts[session.id].to_i) }.sort_by(&:fill_rate)
      end
    end

    private

    def at_risk(session, confirmed)
      fill_rate = (confirmed * 100.0 / session.max_players).round
      AtRisk.new(session: session, confirmed: confirmed, fill_rate: fill_rate) if fill_rate < AT_RISK_FILL
    end
  end
end
