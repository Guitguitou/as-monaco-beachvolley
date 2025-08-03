class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :level, optional: true
  has_one :balance, dependent: :destroy
  has_many :credit_transactions, dependent: :destroy
  after_create :init_balance

  scope :coachs, -> { where(coach: true) }
  scope :responsables, -> { where(responsable: true) }
  scope :admins, -> { where(admin: true) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def credit_balance
    credit_transactions.sum(:amount)
  end

  private

  def init_balance
    create_balance(amount: 0)
  end
end
