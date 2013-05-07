class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string      :type
      t.string      :state
      t.string      :key
      t.integer     :from_id   
      t.integer     :to_id   
      t.string      :email
      t.text        :data
      t.timestamp   :expires_at

      t.timestamps
    end
    
    add_index :requests, [:type, :key, :state]
    add_index :requests, [:from_id, :to_id]
  end
end
