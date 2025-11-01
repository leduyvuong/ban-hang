class AddUserToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :user, foreign_key: true, index: true
  end
end
