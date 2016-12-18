# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161217174949) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "bankaccounts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "charges", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "creditcardaccounts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "disputes", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "imports", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "status",         default: 0,  null: false
    t.integer  "imported_type",  default: 0,  null: false
    t.integer  "imported_count", default: 0
    t.integer  "total_count",    default: 0
    t.string   "last_id",        default: ""
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "refunds", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "returns", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "import_id",               null: false
    t.integer  "user_id",                 null: false
    t.jsonb    "data",       default: {}, null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "stripe_access_token", default: ""
    t.json     "stripe_info",         default: {}
    t.json     "balance",             default: {}
    t.datetime "balance_updated_at"
  end

  add_foreign_key "charges", "imports"
  add_foreign_key "charges", "users"
  add_foreign_key "imports", "users"
end
