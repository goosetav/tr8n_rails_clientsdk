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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130506225643) do

  create_table "requests", :force => true do |t|
    t.string   "type"
    t.string   "state"
    t.string   "key"
    t.integer  "from_id"
    t.integer  "to_id"
    t.string   "email"
    t.text     "data"
    t.datetime "expires_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "requests", ["from_id", "to_id"], :name => "index_requests_on_from_id_and_to_id"
  add_index "requests", ["type", "key", "state"], :name => "index_requests_on_type_and_key_and_state"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "name"
    t.string   "gender"
    t.string   "locale"
    t.datetime "password_set_at"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"

end
