# frozen_string_literal: true

module Admin
  # Formulaire des règles du club : expose les prix en euros et les convertit
  # en centimes avant d'enregistrer le ClubSetting injecté.
  class ClubRulesForm
    RULE_ATTRIBUTES = %i[
      priority_window_hours registration_deadline_hour registration_opening_days
      cancellation_deadline_mode cancellation_deadline_hour cancellation_hours_before
    ].freeze
    EURO_ATTRIBUTES = ClubSetting::SESSION_TYPES.map { |type| :"#{type}_price_euros" }.freeze

    attr_reader :setting

    delegate(*RULE_ATTRIBUTES, :errors, to: :setting)

    def initialize(setting)
      @setting = setting
    end

    ClubSetting::SESSION_TYPES.each do |type|
      define_method(:"#{type}_price_euros") do
        cents = setting.public_send(:"#{type}_price_cents")
        cents && format("%.2f", cents / 100.0)
      end
    end

    def save(params)
      setting.assign_attributes(params.permit(*RULE_ATTRIBUTES).to_h)
      ClubSetting::SESSION_TYPES.each do |type|
        setting.public_send(:"#{type}_price_cents=", to_cents(params[:"#{type}_price_euros"]))
      end
      return true if setting.save

      expose_price_errors_on_euro_fields
      false
    end

    private

    # Les erreurs de prix portent sur les centimes ; le formulaire affiche
    # les champs en euros.
    def expose_price_errors_on_euro_fields
      ClubSetting::SESSION_TYPES.each do |type|
        setting.errors[:"#{type}_price_cents"].each do |message|
          setting.errors.add(:"#{type}_price_euros", message)
        end
      end
    end

    # Montant en euros (virgule ou point) vers centimes ; nil si illisible,
    # ce que la validation du ClubSetting signale.
    def to_cents(value)
      amount = BigDecimal(value.to_s.tr(",", ".").strip, exception: false)
      amount && (amount * 100).round.to_i
    end
  end
end
