class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :level, optional: true
  has_one :balance, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :confirmed_registrations, -> { where(status: Registration.statuses[:confirmed]) }, class_name: 'Registration'
  has_many :sessions_registered, through: :confirmed_registrations, source: :session
  after_create :init_balance

  scope :coachs, -> { where(coach: true) }
  scope :responsables, -> { where(responsable: true) }
  scope :admins, -> { where(admin: true) }
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
end
