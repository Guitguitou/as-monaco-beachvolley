# frozen_string_literal: true

# Métadonnées (titre, description, image) lues sur la page du script Google,
# reprises dans les aperçus de lien (WhatsApp, réseaux sociaux…).
class AddMetaToPublicPages < ActiveRecord::Migration[8.0]
  def change
    add_column :public_pages, :meta_title, :string
    add_column :public_pages, :meta_description, :text
    add_column :public_pages, :meta_image, :string
  end
end
