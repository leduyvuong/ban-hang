class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0
      t.string :remember_token
      t.datetime :remember_token_expires_at
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.jsonb :cart_data, null: false, default: []

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :remember_token
    add_index :users, :reset_password_token, unique: true
  end
end
