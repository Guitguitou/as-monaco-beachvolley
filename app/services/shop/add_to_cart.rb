# frozen_string_literal: true

module Shop
  # Ajoute un article au panier d'un membre pour une campagne. Le prix vient
  # toujours de la coupe, jamais du formulaire ; un même article (coupe,
  # coloris, taille) déjà au panier voit sa quantité augmenter.
  class AddToCart
    Result = Data.define(:line, :error)

    def initialize(user:, campaign:, cut:, color:, size:, quantity:)
      @user = user
      @campaign = campaign
      @cut = cut
      @color = color
      @size = size
      @quantity = quantity.to_i
    end

    def call
      error = refusal
      return Result.new(line: nil, error: error) if error

      line = OrderLine.find_or_initialize_by(order: cart, cut: @cut, color: @color, size: @size)
      line.assign_attributes(snapshot.merge(quantity: line.quantity.to_i + @quantity))
      line.save ? Result.new(line: line, error: nil) : Result.new(line: nil, error: line.errors.full_messages.to_sentence)
    end

    private

    def refusal
      return "Les commandes sont fermées." unless @campaign&.accepting_orders?
      return "Cet article n'est plus en vente." unless product.active?
      return "Ce coloris n'existe pas pour cet article." unless @color&.product_id == product.id

      "Choisis une taille de la liste." unless @cut.sizes.include?(@size)
    end

    def product = @cut.product

    def cart = Order.cart_for(@user, @campaign) || Order.create!(user: @user, campaign: @campaign)

    def snapshot
      { product: product, product_name: product.name, cut_label: @cut.label, color_name: @color.name, unit_price_cents: @cut.price_cents }
    end
  end
end
