# frozen_string_literal: true

class CreateNotificationRules < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_rules do |t|
      t.string :name, null: false
      t.string :event_type, null: false
      t.jsonb :conditions, default: {}
      t.boolean :enabled, default: true, null: false
      t.text :title_template
      t.text :body_template
      t.timestamps null: false
    end

    add_index :notification_rules, :event_type
    add_index :notification_rules, :enabled
  end
end
