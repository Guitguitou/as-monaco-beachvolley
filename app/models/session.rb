class Session < ApplicationRecord
  TRAINING_PRICE = 400
  FREE_PLAY_PRICE = 300
  PRIVATE_COACHING_PRICE = 1500
  STAGE_PRICE = 0
  PRICE_BY_TYPE = {
    "entrainement" => TRAINING_PRICE,
    "jeu_libre" => FREE_PLAY_PRICE,
    "coaching_prive" => PRIVATE_COACHING_PRICE,
    "stage" => STAGE_PRICE
  }.freeze
  belongs_to :user
  has_many :session_levels, dependent: :destroy
  has_many :levels, through: :session_levels
  has_many :registrations, dependent: :destroy
  has_many :participants, through: :registrations, source: :user
  has_many :late_cancellations, dependent: :destroy
  validates :title, :start_at, :end_at, :session_type, :user_id, :terrain, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  accepts_nested_attributes_for :registrations, allow_destroy: true

  enum :session_type, {
    entrainement: "entrainement",
    jeu_libre: "jeu_libre",
    tournoi: "tournoi",
    coaching_prive: "coaching_prive",
    stage: "stage"
  }

  enum :terrain, {
    "Terrain 1": 1,
    "Terrain 2": 2,
    "Terrain 3": 3
  }

  before_validation { Sessions::TypeDefaults.apply(self) }

  validates_with Sessions::ScheduleValidator, Sessions::RosterValidator
  validate :coach_has_enough_credits_for_private_coaching, if: :coaching_prive?

  after_create :charge_coach_for_private_coaching, if: :coaching_prive?

  scope :terrain, ->(terrain) { where(terrain: terrain) }
  scope :upcoming, -> { where("start_at >= ?", Time.current) }
  scope :in_week, ->(week_start) { where(start_at: week_start..(week_start + 7.days)) }
  scope :in_month, ->(month_start) { where(start_at: month_start..month_start.end_of_month) }
  scope :in_current_week, ->(week_start = nil) {
    week_start ||= Time.zone.now.beginning_of_week(:monday)
    in_week(week_start)
  }
  scope :in_current_month, ->(month_start = nil) {
    month_start ||= Time.zone.now.beginning_of_month
    in_month(month_start)
  }
  scope :trainings, -> { where(session_type: "entrainement") }
  scope :free_plays, -> { where(session_type: "jeu_libre") }
  scope :private_coachings, -> { where(session_type: "coaching_prive") }
  scope :for_user_levels, ->(level_ids) do
    Sessions::EligibleForUserLevelsQuery.call(relation: all, level_ids: level_ids)
  end
  scope :ordered_by_start, -> { order(:start_at) }


  PRIORITY_WINDOW_HOURS = 24
  REGISTRATION_DEADLINE_HOUR = 17 # 17h le jour J

  # Returns [boolean, reason]
  # Enforces registration opening rules for trainings with a 24h priority
  # window for users with competition license.
  # @param user [User] The user trying to register
  # @param skip_deadline [Boolean] If true, skip the deadline check (for admins/coaches)
  def registration_open_state_for(user, skip_deadline: false)
    Sessions::RegistrationPolicy.new(session: self, user: user, skip_deadline: skip_deadline).open_state
  end

  # Check if current time is past 17h on the day of the session
  def past_registration_deadline?
    Sessions::RegistrationPolicy.new(session: self, user: nil).past_deadline?
  end

  def display_name
    entrainement? ? "#{title} - #{levels.map(&:display_name).join(', ')}" : title
  end

  def full?
    return false unless max_players.present?
    registrations.confirmed.count >= max_players
  end

  # --- Séries de duplication ----------------------------------------------
  # Les sessions issues d'une même duplication partagent un `series_id`.
  # Navigation unidirectionnelle par requête (pas d'association has_many).

  def series?
    series_id.present?
  end

  # Toutes les sessions de la série (self inclus). Relation vide si hors série.
  def series_sessions
    return Session.where(id: id) unless series?
    Session.where(series_id: series_id)
  end

  # Cette session et les suivantes de la série (start_at >= self.start_at).
  # Avec including_self: false, on exclut la session courante.
  def following_in_series(including_self: true)
    return Session.where(id: id) if !series? && including_self
    return Session.none unless series?

    operator = including_self ? ">=" : ">"
    series_sessions.where("start_at #{operator} ?", start_at)
  end

  # Y a-t-il d'autres sessions de la série strictement après celle-ci ?
  def has_following_in_series?
    series? && following_in_series(including_self: false).exists?
  end

  # Promote the earliest waitlisted user to confirmed if a spot is available
  def promote_from_waitlist!
    rebalance!
  end

  # Applique l'invariant de priorité : la liste principale = les max_players
  # inscriptions triées par [priorité, created_at]. Déplace les joueurs
  # secondaires si un prioritaire s'inscrit, et promeut sinon.
  def rebalance!
    Sessions::PriorityBalancerService.call(session: self)
  end

  # Groupe(s) prioritaire(s) de la session (plus petit rang de priorité).
  def priority_levels
    levels_by_priority_rank.first
  end

  # Groupe(s) secondaire(s) (rang de priorité au-dessus du plus prioritaire).
  def secondary_levels
    levels_by_priority_rank.last
  end

  # Met à jour le rang de priorité de chaque session_level à partir d'un hash
  # { level_id => rang }. Appelé après (ré)affectation de level_ids.
  def sync_level_priorities(priorities_hash)
    return if priorities_hash.blank?

    session_levels.each do |session_level|
      rank = priorities_hash[session_level.level_id.to_s] || priorities_hash[session_level.level_id]
      next if rank.blank?
      session_level.update_column(:priority, rank.to_i)
    end
  end

  private

  # [niveaux au meilleur rang, autres niveaux], chacun dans l'ordre de priorité.
  def levels_by_priority_rank
    ordered = session_levels.ordered_by_priority.includes(:level).to_a
    top = ordered.first&.priority
    ordered.partition { |session_level| session_level.priority == top }.map { |group| group.map(&:level) }
  end

  def coach_has_enough_credits_for_private_coaching
    return if Sessions::PrivateCoachingChargeService.new(session: self).coach_can_pay?

    errors.add(:base, "Le coach n'a pas assez de crédits pour créer un coaching privé (#{price} requis)")
  end

  def charge_coach_for_private_coaching
    Sessions::PrivateCoachingChargeService.new(session: self).charge_coach!
  end
end
