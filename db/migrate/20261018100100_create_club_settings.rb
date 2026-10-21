# frozen_string_literal: true

class CreateClubSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :club_settings do |t|
      t.string :membership_form_url
      t.timestamps
    end
  end
end
