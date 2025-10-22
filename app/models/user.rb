class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Soft-disable accounts: when disabled, login is prevented and no actions allowed
  def active_for_authentication?
    super && !disabled?
  end

  def disabled?
    self.disabled_at.present?
  end

  def inactive_message
    disabled? ? :locked : super
  end

  # Backward-compat virtual association for specs/legacy code
  # Allows create(:user, level: some_level) to assign a primary level
  def level=(level_obj)
    @legacy_level_to_assign = level_obj
  end

  def level
    levels.first
  end

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
  scope :gender, ->(g) { joins(:levels).where(levels: { gender: g }) }
  scope :with_license, ->(lic) { where(license_type: lic) }
  scope :with_enough_credits, ->(session_record) {
    joins(:balance).where("balances.amount >= ?", session_record.price)
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def credit_balance
    credit_transactions.sum(:amount)
  end

  # Salary helpers
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
