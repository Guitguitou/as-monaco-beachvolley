# frozen_string_literal: true

# User model representing users of the AS Monaco Beach Volley application.
#
# Handles:
# - Authentication via Devise
# - Account activation (licence payment)
# - Account disabling for management
# - Multiple levels assignment
# - Credit balance management
# - Salary tracking for coaches
#
# Non-activated users can login but have limited access (see Ability model).
class User < ApplicationRecord
  include Disableable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_levels, dependent: :destroy
  has_many :levels, through: :user_levels
  has_one :balance, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  has_many :credit_purchases, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :confirmed_registrations, -> { where(status: Registration.statuses[:confirmed]) }, class_name: 'Registration'
  has_many :sessions_registered, through: :confirmed_registrations, source: :session

  after_create :init_balance
  after_create :apply_legacy_level_assignment

  scope :coachs, -> { where(coach: true) }
  scope :responsables, -> { where(responsable: true) }
  scope :admins, -> { where(admin: true) }
  scope :financial_managers, -> { where(financial_manager: true) }
  scope :activated, -> { where.not(activated_at: nil) }
  scope :not_activated, -> { where(activated_at: nil) }
  scope :gender, ->(g) { joins(:levels).where(levels: { gender: g }) }
  scope :with_license, ->(lic) { where(license_type: lic) }
  scope :with_enough_credits, lambda { |session_record|
    joins(:balance).where('balances.amount >= ?', session_record.price)
  }

  # Prevent login when account is disabled.
  # Non-activated users can login but have limited access.
  def active_for_authentication?
    super && !disabled?
  end

  def inactive_message
    return :locked if disabled?

    super
  end

  def activated?
    activated_at.present?
  end

  def activate!
    update!(activated_at: Time.current) unless activated?
  end

  # Backward-compat: allows create(:user, level: some_level) to assign a primary level
  def level=(level_obj)
    @legacy_level_to_assign = level_obj
  end

  def level
    levels.first
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def credit_balance
    balance&.amount || 0
  end

  # Salary helpers: stored in cents, exposed as euros
  def salary_per_training
    (salary_per_training_cents || 0) / 100.0
  end

  def salary_per_training=(euros)
    self.salary_per_training_cents = (euros.to_f * 100).round
  end

  private

  def init_balance
    create_balance(amount: 0)
  end

  def apply_legacy_level_assignment
    return unless @legacy_level_to_assign.present?

    user_levels.find_or_create_by!(level: @legacy_level_to_assign)
  end
end
