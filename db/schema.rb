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

ActiveRecord::Schema[8.0].define(version: 2026_01_20_120020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

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

  create_table "notification_rules", force: :cascade do |t|
    t.string "name", null: false
    t.string "event_type", null: false
    t.jsonb "conditions", default: {}
    t.boolean "enabled", default: true, null: false
    t.text "title_template"
    t.text "body_template"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_notification_rules_on_enabled"
    t.index ["event_type"], name: "index_notification_rules_on_event_type"
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

  create_table "plans_hebdomadaires", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "plan_mensuel_id", null: false
    t.date "debut_semaine", null: false
    t.decimal "jours_homme", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_mensuel_id", "debut_semaine"], name: "index_plans_hebdomadaires_on_plan_mensuel_id_and_debut_semaine", unique: true
    t.index ["plan_mensuel_id"], name: "index_plans_hebdomadaires_on_plan_mensuel_id"
  end

  create_table "plans_mensuels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "mois", null: false
    t.integer "cible_ca_cents", default: 0, null: false
    t.decimal "jours_homme", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mois"], name: "index_plans_mensuels_on_mois", unique: true
  end

  create_table "player_listing_levels", force: :cascade do |t|
    t.bigint "player_listing_id", null: false
    t.bigint "level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_player_listing_levels_on_level_id"
    t.index ["player_listing_id", "level_id"], name: "index_player_listing_levels_on_player_listing_id_and_level_id", unique: true
    t.index ["player_listing_id"], name: "index_player_listing_levels_on_player_listing_id"
  end

  create_table "player_listings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id"
    t.string "listing_type", null: false
    t.string "gender"
    t.date "date"
    t.time "starts_at"
    t.time "ends_at"
    t.string "status", default: "active", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_player_listings_on_session_id"
    t.index ["status", "listing_type", "date"], name: "index_player_listings_on_status_and_listing_type_and_date"
    t.index ["user_id"], name: "index_player_listings_on_user_id"
  end

  create_table "player_requests", force: :cascade do |t|
    t.bigint "player_listing_id", null: false
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.string "status", default: "pending", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_player_requests_on_from_user_id"
    t.index ["player_listing_id"], name: "index_player_requests_on_player_listing_id"
    t.index ["to_user_id", "status"], name: "index_player_requests_on_to_user_id_and_status"
    t.index ["to_user_id"], name: "index_player_requests_on_to_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
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

  create_table "regles_statuts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "statut", null: false
    t.integer "categorie_couleur", null: false
    t.boolean "compte_comme_fait", default: false, null: false
    t.integer "ordre", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ordre"], name: "index_regles_statuts_on_ordre"
    t.index ["statut"], name: "index_regles_statuts_on_statut", unique: true
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

  create_table "tickets_production", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "plan_hebdomadaire_id", null: false
    t.string "cle_jira", null: false
    t.string "url_jira", null: false
    t.string "titre"
    t.integer "valeur_cents", default: 0, null: false
    t.string "statut", null: false
    t.date "prevu_le", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_hebdomadaire_id"], name: "index_tickets_production_on_plan_hebdomadaire_id"
    t.index ["prevu_le"], name: "index_tickets_production_on_prevu_le"
    t.index ["statut"], name: "index_tickets_production_on_statut"
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
    t.datetime "activated_at"
    t.boolean "financial_manager", default: false, null: false
    t.index ["activated_at"], name: "index_users_on_activated_at"
    t.index ["admin", "id"], name: "index_users_on_admin_and_id"
    t.index ["coach", "id"], name: "index_users_on_coach_and_id"
    t.index ["disabled_at"], name: "index_users_on_disabled_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["financial_manager"], name: "index_users_on_financial_manager"
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
  add_foreign_key "plans_hebdomadaires", "plans_mensuels", column: "plan_mensuel_id"
  add_foreign_key "player_listing_levels", "levels"
  add_foreign_key "player_listing_levels", "player_listings"
  add_foreign_key "player_listings", "sessions"
  add_foreign_key "player_listings", "users"
  add_foreign_key "player_requests", "player_listings"
  add_foreign_key "player_requests", "users", column: "from_user_id"
  add_foreign_key "player_requests", "users", column: "to_user_id"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "registrations", "sessions"
  add_foreign_key "registrations", "users"
  add_foreign_key "session_levels", "levels"
  add_foreign_key "session_levels", "sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "stages", "users", column: "assistant_coach_id"
  add_foreign_key "stages", "users", column: "main_coach_id"
  add_foreign_key "tickets_production", "plans_hebdomadaires", column: "plan_hebdomadaire_id"
  add_foreign_key "user_levels", "levels"
  add_foreign_key "user_levels", "users"
end
