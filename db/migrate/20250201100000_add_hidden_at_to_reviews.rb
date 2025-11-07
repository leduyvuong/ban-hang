class AddHiddenAtToReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :reviews, :hidden_at, :datetime
    add_index :reviews, :hidden_at
  end
end
