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

ActiveRecord::Schema[8.1].define(version: 2026_02_08_212250) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assemblies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "subdomain"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_assemblies_on_name", unique: true
    t.index ["subdomain"], name: "index_assemblies_on_subdomain", unique: true
  end

  create_table "member_of_assemblies", force: :cascade do |t|
    t.integer "assembly_id", null: false
    t.datetime "created_at", null: false
    t.integer "member_id", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["assembly_id", "member_id", "year"], name: "index_member_of_assemblies_on_assembly_member_year", unique: true
    t.index ["assembly_id"], name: "index_member_of_assemblies_on_assembly_id"
    t.index ["member_id"], name: "index_member_of_assemblies_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.integer "assembly_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["assembly_id", "name"], name: "index_members_on_assembly_id_and_name"
    t.index ["assembly_id"], name: "index_members_on_assembly_id"
  end

  create_table "performances", force: :cascade do |t|
    t.integer "assembly_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "location"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["assembly_id", "date"], name: "index_performances_on_assembly_id_and_date"
    t.index ["assembly_id"], name: "index_performances_on_assembly_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "assembly_id"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["assembly_id"], name: "index_users_on_assembly_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "member_of_assemblies", "assemblies"
  add_foreign_key "member_of_assemblies", "members"
  add_foreign_key "members", "assemblies"
  add_foreign_key "performances", "assemblies"
end
