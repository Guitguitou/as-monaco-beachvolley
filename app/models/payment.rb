class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :credit_package

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
    cancelled: 'cancelled',
    refunded: 'refunded'
  }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :sherlock_transaction_id, uniqueness: true, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: ['completed']) }

  before_create :set_amount_from_package

  def amount
    amount_cents / 100.0
  end

  def amount=(euros)
    self.amount_cents = (euros.to_f * 100).round
  end

  def complete!
    return false unless pending? || processing?

    transaction do
      update!(status: 'completed')
      # Créer la transaction de crédit
      user.credit_transactions.create!(
        amount: credit_package.credits,
        transaction_type: 'purchase',
        description: "Achat de #{credit_package.name}",
        payment: self
      )
    end
  end

  def fail!
    update!(status: 'failed')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  private

  def set_amount_from_package
    self.amount_cents = credit_package.price_cents if amount_cents.nil?
  end
end
