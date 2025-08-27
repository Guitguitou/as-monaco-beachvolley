class BackfillUserLevelsAndRemoveLevelId < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Backfilling user_levels from users.level_id" do
      execute <<-SQL.squish
        INSERT INTO user_levels (user_id, level_id, created_at, updated_at)
        SELECT id AS user_id, level_id, NOW(), NOW()
        FROM users
        WHERE level_id IS NOT NULL
        ON CONFLICT (user_id, level_id) DO NOTHING
      SQL
    end

    remove_reference :users, :level, foreign_key: true
  end

  def down
    add_reference :users, :level, foreign_key: true

    # We won't backfill level_id reliably on down; leave nulls
  end
end
