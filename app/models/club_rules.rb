# frozen_string_literal: true

# Règles du club : prix des séances, fenêtres d'inscription et fuseau horaire.
# Un seul point d'accès, `ClubRules.current` ; le reste du code reçoit ces
# règles par injection (`rules: ClubRules.current`).
class ClubRules < Data.define(
  :price_by_type, :priority_window_hours, :registration_deadline_hour,
  :registration_opening_days, :cancellation_deadline_mode, :cancellation_deadline_hour,
  :cancellation_hours_before, :season_start_month, :time_zone
)
  DEFAULT_PRICE_BY_TYPE = {
    "entrainement" => 400,
    "jeu_libre" => 300,
    "coaching_prive" => 1500,
    "stage" => 0
  }.freeze

  def self.default
    new(
      price_by_type: DEFAULT_PRICE_BY_TYPE,
      priority_window_hours: 24,
      registration_deadline_hour: 17, # 17h le jour J
      registration_opening_days: 7,
      cancellation_deadline_mode: "eve_at_hour",
      cancellation_deadline_hour: 22, # 22h la veille
      cancellation_hours_before: 24,
      season_start_month: 9, # septembre
      time_zone: Rails.application.config.time_zone
    )
  end

  # Règles enregistrées par l'admin, lues une fois par requête ou job.
  def self.current
    CurrentClubRules.rules ||= from_setting(ClubSetting.current)
  end

  def self.from_setting(setting)
    new(
      price_by_type: setting.price_by_type,
      priority_window_hours: setting.priority_window_hours,
      registration_deadline_hour: setting.registration_deadline_hour,
      registration_opening_days: setting.registration_opening_days,
      cancellation_deadline_mode: setting.cancellation_deadline_mode,
      cancellation_deadline_hour: setting.cancellation_deadline_hour,
      cancellation_hours_before: setting.cancellation_hours_before,
      season_start_month: setting.season_start_month,
      time_zone: Rails.application.config.time_zone
    )
  end

  def initialize(price_by_type:, **rules)
    super(price_by_type: price_by_type.to_h.transform_keys(&:to_s).freeze, **rules)
  end

  # Prix en centimes d'un type de séance, 0 pour un type inconnu.
  def price_for(session_type)
    price_by_type.fetch(session_type.to_s, 0)
  end

  def priority_window
    priority_window_hours.hours
  end

  # Fin de la fenêtre de priorité licence compétition.
  def priority_ends_at(opens_at)
    opens_at + priority_window
  end

  # Heure limite d'inscription le jour de la séance.
  def registration_deadline_for(start_at)
    start_at.change(hour: registration_deadline_hour, min: 0, sec: 0)
  end

  def registration_opens_at_for(start_at)
    start_at - registration_opening_days.days
  end

  # Limite de désinscription remboursée : la veille à l'heure fixée, ou un
  # nombre d'heures avant le début selon le mode choisi par le club.
  def cancellation_deadline_for(start_at)
    if cancellation_deadline_mode == "hours_before"
      start_at - cancellation_hours_before.hours
    else
      (start_at - 1.day).change(hour: cancellation_deadline_hour, min: 0)
    end
  end

  def zone
    ActiveSupport::TimeZone[time_zone]
  end
end
