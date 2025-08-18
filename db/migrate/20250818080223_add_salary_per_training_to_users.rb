class AddSalaryPerTrainingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :salary_per_training_cents, :integer, null: false, default: 0
  end
end
