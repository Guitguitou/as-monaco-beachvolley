# frozen_string_literal: true

module Sherlock
  # Réponse signée de Sherlock's, qu'elle arrive par le navigateur du client
  # (normalReturnUrl, en POST cross-site) ou de serveur à serveur
  # (automaticResponseUrl). Les deux portent le même couple Data / Seal, donc
  # la même vérification et la même lecture.
  class Response
    def self.from_params(params, seal: Seal.from_env)
      new(data: params[:Data].to_s, seal_value: params[:Seal].to_s, seal: seal)
    end

    def initialize(data:, seal_value:, seal: Seal.from_env)
      @data = data
      @seal_value = seal_value
      @seal = seal
    end

    def valid?
      seal.valid?(data, seal_value)
    end

    def fields
      @fields ||= DataParser.parse(data)
    end

    def reference
      fields["transactionReference"].presence || fields["orderId"].presence
    end

    def response_code
      fields["responseCode"]
    end

    private

    attr_reader :data, :seal_value, :seal
  end
end
