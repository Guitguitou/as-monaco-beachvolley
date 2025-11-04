class AddActivatedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :activated_at, :datetime
    add_index :users, :activated_at
    
    # Rétrocompatibilité : activer tous les comptes existants
    # (les nouveaux seront inactifs par défaut)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET activated_at = created_at WHERE activated_at IS NULL
        SQL
      end
    end
  end
end
