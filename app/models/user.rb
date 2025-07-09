class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :level, optional: true

  scope :coachs, -> { where(coach: true) }
  scope :responsables, -> { where(responsable: true) }
  scope :admins, -> { where(admin: true) }

  def full_name
    "#{first_name} #{last_name}"
  end
end
