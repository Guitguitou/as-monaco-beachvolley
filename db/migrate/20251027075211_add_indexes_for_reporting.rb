class AddIndexesForReporting < ActiveRecord::Migration[8.0]
  def change
    # Indexes for sessions table
    add_index :sessions, [:session_type, :start_at], name: 'index_sessions_on_type_and_start_at'
    add_index :sessions, [:user_id, :start_at], name: 'index_sessions_on_user_and_start_at'
    add_index :sessions, [:start_at, :session_type], name: 'index_sessions_on_start_at_and_type'
    
    # Indexes for credit_transactions table
    add_index :credit_transactions, [:transaction_type, :created_at], name: 'index_credit_transactions_on_type_and_created_at'
    add_index :credit_transactions, [:session_id, :transaction_type], name: 'index_credit_transactions_on_session_and_type'
    add_index :credit_transactions, [:created_at, :transaction_type], name: 'index_credit_transactions_on_created_at_and_type'
    
    # Indexes for credit_purchases table
    add_index :credit_purchases, [:status, :paid_at], name: 'index_credit_purchases_on_status_and_paid_at'
    add_index :credit_purchases, [:paid_at, :status], name: 'index_credit_purchases_on_paid_at_and_status'
    
    # Indexes for registrations table
    add_index :registrations, [:status, :created_at], name: 'index_registrations_on_status_and_created_at'
    add_index :registrations, [:session_id, :status], name: 'index_registrations_on_session_and_status'
    
    # Indexes for late_cancellations table
    add_index :late_cancellations, [:created_at], name: 'index_late_cancellations_on_created_at'
    add_index :late_cancellations, [:session_id, :created_at], name: 'index_late_cancellations_on_session_and_created_at'
    
    # Indexes for users table
    add_index :users, [:coach, :id], name: 'index_users_on_coach_and_id'
    add_index :users, [:admin, :id], name: 'index_users_on_admin_and_id'
  end
end