# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_19_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "balances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_balances_on_user_id"
  end

  create_table "credit_transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id"
    t.integer "transaction_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_credit_transactions_on_session_id"
    t.index ["user_id"], name: "index_credit_transactions_on_user_id"
  end

  create_table "levels", force: :cascade do |t|
    t.string "name"
    t.string "gender"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["session_id", "status", "created_at"], name: "index_registrations_on_session_status_created_at"
    t.index ["session_id"], name: "index_registrations_on_session_id"
    t.index ["user_id", "session_id"], name: "index_registrations_on_user_id_and_session_id", unique: true
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "session_levels", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.bigint "level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_session_levels_on_level_id"
    t.index ["session_id"], name: "index_session_levels_on_session_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "session_type"
    t.bigint "user_id", null: false
    t.integer "max_players"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "terrain"
    t.integer "price", default: 0, null: false
    t.datetime "cancellation_deadline_at"
    t.datetime "registration_opens_at"
    t.text "coach_notes"
    t.index ["registration_opens_at"], name: "index_sessions_on_registration_opens_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin"
    t.boolean "coach"
    t.boolean "responsable"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "level_id"
    t.integer "salary_per_training_cents", default: 0, null: false
    t.string "license_type"
    t.datetime "disabled_at"
    t.index ["disabled_at"], name: "index_users_on_disabled_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["level_id"], name: "index_users_on_level_id"
    t.index ["license_type"], name: "index_users_on_license_type"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "balances", "users"
  add_foreign_key "credit_transactions", "sessions"
  add_foreign_key "credit_transactions", "users"
  add_foreign_key "registrations", "sessions"
  add_foreign_key "registrations", "users"
  add_foreign_key "session_levels", "levels"
  add_foreign_key "session_levels", "sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "levels"
end
