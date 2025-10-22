module Sherlock
  class CreatePayment
    attr_reader :credit_purchase

    def initialize(credit_purchase)
      @credit_purchase = credit_purchase
    end

    def call
      gateway = Gateway.build

      payment_url = gateway.create_payment(
        reference: credit_purchase.sherlock_transaction_reference,
        amount_cents: credit_purchase.amount_cents,
        currency: credit_purchase.currency,
        return_urls: {
          success: success_url,
          cancel: cancel_url
        },
        customer: {
          email: credit_purchase.user.email,
          name: credit_purchase.user.full_name
        }
      )

      payment_url
    end

    private

    def success_url
      ENV.fetch('SHERLOCK_RETURN_URL_SUCCESS', "#{app_host}/checkout/success")
    end

    def cancel_url
      ENV.fetch('SHERLOCK_RETURN_URL_CANCEL', "#{app_host}/checkout/cancel")
    end

    def app_host
      ENV.fetch('APP_HOST', 'http://localhost:3000')
    end
  end
end

