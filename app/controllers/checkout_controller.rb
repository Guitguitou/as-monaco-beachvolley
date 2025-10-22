class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def success
    @reference = params[:reference]
    @credit_purchase = current_user.credit_purchases.find_by(sherlock_transaction_reference: @reference) if @reference
    
    # En mode fake, on traite immédiatement le paiement
    if params[:fake] == 'true' && @credit_purchase
      Sherlock::HandleCallback.new(
        reference: @reference,
        status: 'paid',
        amount: @credit_purchase.amount_cents,
        currency: @credit_purchase.currency
      ).call
      
      @credit_purchase.reload
    end
  end

  def cancel
    @reference = params[:reference]
    @credit_purchase = current_user.credit_purchases.find_by(sherlock_transaction_reference: @reference) if @reference
    
    if @credit_purchase
      @credit_purchase.update!(status: :cancelled)
    end
  end
end

