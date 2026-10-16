# frozen_string_literal: true

module Admin
  class GroupsController < BaseController
    before_action :require_admin!

    def index
      @level_groups = Users::LevelGroups.new
    end
  end
end
