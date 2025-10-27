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

ActiveRecord::Schema[8.0].define(version: 2025_10_27_075211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_balances_on_user_id"
  end

  create_table "credit_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "EUR", null: false
    t.integer "credits", null: false
    t.string "status", default: "pending", null: false
    t.string "sherlock_transaction_reference"
    t.jsonb "sherlock_fields", default: {}
    t.datetime "paid_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pack_id"
    t.index ["created_at"], name: "index_credit_purchases_on_created_at"
    t.index ["pack_id"], name: "index_credit_purchases_on_pack_id"
    t.index ["paid_at", "status"], name: "index_credit_purchases_on_paid_at_and_status"
    t.index ["sherlock_transaction_reference"], name: "index_credit_purchases_on_sherlock_transaction_reference", unique: true, where: "(sherlock_transaction_reference IS NOT NULL)"
    t.index ["status", "paid_at"], name: "index_credit_purchases_on_status_and_paid_at"
    t.index ["status"], name: "index_credit_purchases_on_status"
    t.index ["user_id"], name: "index_credit_purchases_on_user_id"
  end

  create_table "credit_transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id"
    t.integer "transaction_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "transaction_type"], name: "index_credit_transactions_on_created_at_and_type"
    t.index ["session_id", "transaction_type"], name: "index_credit_transactions_on_session_and_type"
    t.index ["session_id"], name: "index_credit_transactions_on_session_id"
    t.index ["transaction_type", "created_at"], name: "index_credit_transactions_on_type_and_created_at"
    t.index ["user_id"], name: "index_credit_transactions_on_user_id"
  end

  create_table "late_cancellations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_late_cancellations_on_created_at"
    t.index ["session_id", "created_at"], name: "index_late_cancellations_on_session_and_created_at"
    t.index ["session_id"], name: "index_late_cancellations_on_session_id"
    t.index ["user_id", "created_at"], name: "index_late_cancellations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_late_cancellations_on_user_id"
  end

  create_table "levels", force: :cascade do |t|
    t.string "name"
    t.string "gender"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "packs", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "pack_type", default: "credits", null: false
    t.integer "amount_cents", null: false
    t.integer "credits"
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stage_id"
    t.index ["active"], name: "index_packs_on_active"
    t.index ["pack_type"], name: "index_packs_on_pack_type"
    t.index ["position"], name: "index_packs_on_position"
    t.index ["stage_id"], name: "index_packs_on_stage_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["session_id", "status", "created_at"], name: "index_registrations_on_session_status_created_at"
    t.index ["session_id", "status"], name: "index_registrations_on_session_and_status"
    t.index ["session_id"], name: "index_registrations_on_session_id"
    t.index ["status", "created_at"], name: "index_registrations_on_status_and_created_at"
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
    t.index ["session_type", "start_at"], name: "index_sessions_on_type_and_start_at"
    t.index ["start_at", "session_type"], name: "index_sessions_on_start_at_and_type"
    t.index ["user_id", "start_at"], name: "index_sessions_on_user_and_start_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stages", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.date "starts_on"
    t.date "ends_on"
    t.bigint "main_coach_id"
    t.bigint "assistant_coach_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_cents"
    t.string "registration_link"
    t.index ["assistant_coach_id"], name: "index_stages_on_assistant_coach_id"
    t.index ["main_coach_id"], name: "index_stages_on_main_coach_id"
  end

  create_table "user_levels", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_user_levels_on_level_id"
    t.index ["user_id", "level_id"], name: "index_user_levels_on_user_id_and_level_id", unique: true
    t.index ["user_id"], name: "index_user_levels_on_user_id"
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
    t.integer "salary_per_training_cents", default: 0, null: false
    t.string "license_type"
    t.datetime "disabled_at"
    t.index ["admin", "id"], name: "index_users_on_admin_and_id"
    t.index ["coach", "id"], name: "index_users_on_coach_and_id"
    t.index ["disabled_at"], name: "index_users_on_disabled_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["license_type"], name: "index_users_on_license_type"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "balances", "users"
  add_foreign_key "credit_purchases", "packs"
  add_foreign_key "credit_purchases", "users"
  add_foreign_key "credit_transactions", "sessions"
  add_foreign_key "credit_transactions", "users"
  add_foreign_key "late_cancellations", "sessions"
  add_foreign_key "late_cancellations", "users"
  add_foreign_key "packs", "stages"
  add_foreign_key "registrations", "sessions"
  add_foreign_key "registrations", "users"
  add_foreign_key "session_levels", "levels"
  add_foreign_key "session_levels", "sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "stages", "users", column: "assistant_coach_id"
  add_foreign_key "stages", "users", column: "main_coach_id"
  add_foreign_key "user_levels", "levels"
  add_foreign_key "user_levels", "users"
end
