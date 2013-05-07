class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string      :email
      t.string      :crypted_password
      t.string      :salt
      t.string      :name
      t.string      :gender
      t.string      :locale
      t.timestamp   :password_set_at
      
      t.timestamps
    end

    add_index :users, :email
  end
end
