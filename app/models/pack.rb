class Pack < ApplicationRecord
  has_many :credit_purchases, dependent: :nullify
  belongs_to :stage, optional: true

  # Types de packs
  enum :pack_type, {
    credits: "credits",
    licence: "licence",
    stage: "stage",
    inscription_tournoi: "inscription_tournoi",
    equipements: "equipements"
  }, prefix: true

  validates :name, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :pack_type, presence: true
  
  # Validation conditionnelle : credits requis pour les packs de crédits
  validates :credits, presence: true, numericality: { greater_than: 0 }, if: :pack_type_credits?
  
  # Validation conditionnelle : stage_id requis pour les packs de stage
  validates :stage_id, presence: true, if: :pack_type_stage?

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :credits_packs, -> { where(pack_type: :credits) }
  scope :stage_packs, -> { where(pack_type: :stage) }
  scope :licence_packs, -> { where(pack_type: :licence) }
  scope :inscription_tournoi_packs, -> { where(pack_type: :inscription_tournoi) }
  scope :equipements_packs, -> { where(pack_type: :equipements) }

  # Montant en euros
  def amount_eur
    amount_cents / 100.0
  end

  # Setter pour le montant en euros
  def amount_eur=(euros)
    self.amount_cents = (euros.to_f * 100).round
  end

  # Label pour l'affichage
  def display_name
    case pack_type
    when "credits"
      "#{name} - #{credits} crédits (#{amount_eur} €)"
    when "licence"
      "#{name} - Licence (#{amount_eur} €)"
    when "stage"
      stage_name = stage&.title || "Stage"
      "#{name} - #{stage_name} (#{amount_eur} €)"
    when "inscription_tournoi"
      "#{name} - Inscription au tournoi (#{amount_eur} €)"
    when "equipements"
      "#{name} - Equipements (#{amount_eur} €)"
    else
      "#{name} (#{amount_eur} €)"
    end
  end

  # Taux de conversion
  def credits_per_euro
    return 0 unless pack_type_credits? && credits.present? && amount_cents.positive?
    (credits.to_f / amount_eur).round(2)
  end

  # Packs achetables sans être connecté (licence, inscription tournoi, équipements)
  def buyable_without_login?
    pack_type_licence? || pack_type_inscription_tournoi? || pack_type_equipements?
  end
end
