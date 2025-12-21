# frozen_string_literal: true

# Service to handle pack purchase creation
class PackPurchaseService
  def initialize(pack, user)
    @pack = pack
    @user = user
  end

  def call
    validate_pack_active
    validate_user_permissions

    create_credit_purchase
  end

  private

  def validate_pack_active
    return if @pack.active?

    raise StandardError, "Ce pack n'est plus disponible"
  end

  def validate_user_permissions
    return if user_signed_in? && can_buy?
    return if !user_signed_in? && @pack.pack_type_licence?

    raise StandardError, "Vous devez être connecté pour acheter ce pack"
  end

  def user_signed_in?
    @user.present?
  end

  def can_buy?
    Ability.new(@user).can?(:buy, @pack)
  end

  def create_credit_purchase
    if user_signed_in?
      @user.credit_purchases.create!(
        pack: @pack,
        amount_cents: @pack.amount_cents,
        currency: "EUR",
        credits: @pack.credits || 0,
        status: :pending
      )
    else
      CreditPurchase.create!(
        user: nil,
        pack: @pack,
        amount_cents: @pack.amount_cents,
        currency: "EUR",
        credits: @pack.credits || 0,
        status: :pending
      )
    end
  end
end
