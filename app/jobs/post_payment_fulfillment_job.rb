class PostPaymentFulfillmentJob < ApplicationJob
  queue_as :default

  def perform(credit_purchase_id)
    credit_purchase = CreditPurchase.find(credit_purchase_id)

    PaymentMailer.payment_accepted(credit_purchase).deliver_later

    Rails.logger.info("Payment fulfilled for CreditPurchase ##{credit_purchase.id} - User ##{credit_purchase.user_id} received #{credit_purchase.credits} credits")
  end
end

