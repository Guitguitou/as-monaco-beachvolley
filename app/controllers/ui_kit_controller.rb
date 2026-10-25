# frozen_string_literal: true

# UI kit : tous les composants de l'app, avec leurs variantes, sur une page.
#
# Publique mais hors navigation et hors moteurs de recherche. Les données sont
# construites en mémoire (UiKit::Samples) : rien de réel n'y est exposé.
class UiKitController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :redirect_non_activated_users

  def show
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    @samples = UiKit::Samples.new
  end
end
