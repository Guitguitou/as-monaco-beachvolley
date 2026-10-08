class TournamentsController < ApplicationController
  load_and_authorize_resource

  def index
    @upcoming_tournaments = Tournament.upcoming.with_attached_images
    @past_tournaments = Tournament.past.with_attached_images
  end

  def show
    @pack = @tournament.pack
    @paid = @tournament.paid_by?(current_user)
  end
end
