# frozen_string_literal: true

class CreatePublicPages < ActiveRecord::Migration[8.0]
  def change
    create_table :public_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :script_url, null: false
      t.timestamps
    end
    add_index :public_pages, :slug, unique: true
  end
end
