FactoryBot.define do
  factory :credit_transaction do
    user { create(:user) }
    session { nil }
    transaction_type { :training_payment }
    amount { 1 }

    to_create do |transaction|
      persisted = CreditTransaction.record!(
        user: transaction.user,
        session: transaction.session,
        transaction_type: transaction.transaction_type,
        amount: transaction.amount
      )

      if transaction.created_at.present? || transaction.updated_at.present?
        persisted.update_columns(
          created_at: (transaction.created_at || persisted.created_at),
          updated_at: (transaction.updated_at || transaction.created_at || persisted.updated_at)
        )
      end

      transaction.id = persisted.id
      transaction.created_at = persisted.created_at
      transaction.updated_at = persisted.updated_at
    end
  end
end
