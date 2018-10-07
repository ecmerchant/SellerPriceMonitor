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

ActiveRecord::Schema.define(version: 20181001162924) do

  create_table "accounts", force: :cascade do |t|
    t.string   "user"
    t.string   "seller_id"
    t.string   "secret_key"
    t.string   "aws_key"
    t.string   "cw_api_token"
    t.string   "cw_room_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "cw_ids"
    t.integer  "stock_border"
    t.string   "cw_room_id2"
    t.string   "room_id3"
    t.string   "room_id4"
    t.string   "roomid3"
    t.boolean  "test_mode"
    t.boolean  "used_check"
  end

  create_table "products", force: :cascade do |t|
    t.string   "sku"
    t.string   "asin"
    t.integer  "seller_num"
    t.integer  "price"
    t.boolean  "riden"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "user"
    t.boolean  "jriden"
    t.boolean  "checked"
    t.integer  "fba_stock"
    t.boolean  "is_cart_price"
    t.boolean  "validity"
    t.boolean  "revised"
    t.float    "revise_val"
    t.integer  "cart_price"
    t.boolean  "on_sale"
    t.integer  "regular_price"
    t.string   "memo"
    t.boolean  "priced"
    t.boolean  "check_riden"
    t.boolean  "is_fba"
    t.boolean  "checked2"
    t.boolean  "checked3"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "admin_flg"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
