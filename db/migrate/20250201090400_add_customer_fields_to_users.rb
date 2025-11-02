# frozen_string_literal: true

class AddCustomerFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string
    add_column :users, :addresses, :jsonb, default: [], null: false
    add_column :users, :blocked_at, :datetime
    add_index :users, :blocked_at
  end
end
