# frozen_string_literal: true

# User model representing users of the AS Monaco Beach Volley application.
# Includes authentication via Devise and can be disabled for account management.
class User < ApplicationRecord
  include Disableable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :user_levels, dependent: :destroy
  has_many :levels, through: :user_levels
  has_one :balance, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  has_many :credit_purchases, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :confirmed_registrations, -> { where(status: Registration.statuses[:confirmed]) }, class_name: "Registration"
  has_many :sessions_registered, through: :confirmed_registrations, source: :session
  has_many :push_subscriptions, dependent: :destroy

  # Callbacks
  after_create :init_balance
  after_create :apply_legacy_level_assignment

  # Scopes
  scope :coachs, -> { where(coach: true) }
  scope :responsables, -> { where(responsable: true) }
  scope :admins, -> { where(admin: true) }
  scope :financial_managers, -> { where(financial_manager: true) }
  scope :activated, -> { where.not(activated_at: nil) }
  scope :not_activated, -> { where(activated_at: nil) }
  scope :renewed_for_next_season, -> { where(next_season_renewed: true) }
  scope :gender, ->(g) { joins(:levels).where(levels: { gender: g }) }
  scope :with_license, ->(lic) { where(license_type: lic) }
  scope :with_enough_credits, lambda { |session_record|
    joins(:balance).where("balances.amount >= ?", session_record.price)
  }
  scope :players, -> { where.not(admin: true).where.not(coach: true).where.not(responsable: true) }
  scope :male, -> { joins(:levels).where(levels: { gender: "male" }).distinct }
  scope :female, -> { joins(:levels).where(levels: { gender: "female" }).distinct }

  # Nom exigé quand l'utilisateur édite lui-même son profil.
  #
  # Volontairement contextuel : des comptes historiques ont un nom vide, et une
  # validation globale les empêcherait d'être sauvegardés par ailleurs (un
  # admin qui bascule un rôle, par exemple). Le contexte n'est déclenché que
  # par ProfilesController#update.
  validates :first_name, :last_name, presence: true, on: :profile_update

  # Devise: Prevent login when account is disabled
  # Non-activated users can login but have limited access
  def active_for_authentication?
    super && !disabled?
  end

  def inactive_message
    return :locked if disabled?

    super
  end

  # Check if account is activated (licence paid)
  def activated?
    activated_at.present?
  end

  # Activate the account (called when licence is paid)
  def activate!
    update!(activated_at: Time.current) unless activated?
  end

  # Flag that the licence for the upcoming season has been paid.
  # Consumed (reset to false) when an admin resets the season via Licenses::ResetSeason.
  def mark_next_season_renewed!
    update!(next_season_renewed: true) unless next_season_renewed?
  end

  # Backward-compat virtual association for specs/legacy code
  # Allows create(:user, level: some_level) to assign a primary level
  def level=(level_obj)
    @legacy_level_to_assign = level_obj
  end

  def level
    levels.first
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # Rôles ----------------------------------------------------------------
  #
  # Les colonnes de rôle sont des booléens nullables : `admin?` renvoie donc
  # false aussi bien pour false que pour NULL, ce qui est le comportement
  # attendu. Ces prédicats évitent de recopier les combinaisons dans les vues.

  # Encadrant d'une session : coach ou responsable. Les deux ont exactement
  # les mêmes droits dans Ability (cf. app/models/ability.rb).
  def supervisor?
    coach? || responsable?
  end

  # Accès à l'espace d'administration (même condition que la navbar).
  def staff?
    admin? || financial_manager?
  end

  # Joueur « simple » : aucun rôle particulier.
  def player?
    !admin? && !coach? && !responsable? && !financial_manager?
  end

  # Libellés des rôles portés, dans l'ordre d'importance décroissante.
  # Utilisé pour les badges du profil — le responsable financier n'était
  # jusqu'ici jamais affiché nulle part.
  def role_labels
    labels = []
    labels << "Admin" if admin?
    labels << "Coach" if coach?
    labels << "Responsable" if responsable?
    labels << "Responsable financier" if financial_manager?
    labels
  end

  # Returns the current credit balance (maintained by CreditTransaction callbacks)
  def credit_balance
    balance&.amount || 0
  end

  # Salary helpers (stored in cents, exposed as euros)
  def salary_per_training
    (salary_per_training_cents || 0) / 100.0
  end

  def salary_per_training=(euros)
    self.salary_per_training_cents = (euros.to_f * 100).round
  end

  private

  def init_balance
    Users::BootstrapAccount.call(user: self, legacy_level: @legacy_level_to_assign, initialize_balance: true, assign_legacy_level: false)
  end

  def apply_legacy_level_assignment
    Users::BootstrapAccount.call(user: self, legacy_level: @legacy_level_to_assign, initialize_balance: false, assign_legacy_level: true)
  end
end
