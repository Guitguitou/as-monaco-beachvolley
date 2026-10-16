# frozen_string_literal: true

module Users
  # Répartit les joueurs actifs (activés et non désactivés) par niveau,
  # et repère ceux qui appartiennent à plusieurs groupes.
  class LevelGroups
    Group = Struct.new(:level, :members, keyword_init: true)

    def groups
      @groups ||= Level.order(:name).map do |level|
        Group.new(level: level, members: members_by_level.fetch(level.id, []))
      end
    end

    def multi_group?(user)
      group_counts.fetch(user.id, 0) > 1
    end

    private

    def memberships
      @memberships ||= UserLevel.joins(:user)
                                .merge(User.activated.enabled)
                                .includes(:user)
                                .to_a
    end

    def members_by_level
      @members_by_level ||= memberships
        .group_by(&:level_id)
        .transform_values { |uls| uls.map(&:user).sort_by { |u| [ u.last_name.to_s.downcase, u.first_name.to_s.downcase ] } }
    end

    def group_counts
      @group_counts ||= memberships.map(&:user_id).tally
    end
  end
end
