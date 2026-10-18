# frozen_string_literal: true

class AddCancellationToSessionsAndExcusedToLateCancellations < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :cancelled_at, :datetime
    add_column :sessions, :cancellation_reason, :string
    add_index :sessions, :cancelled_at

    add_column :late_cancellations, :excused, :boolean, default: false, null: false
  end
end
