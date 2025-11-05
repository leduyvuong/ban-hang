class CreateCurrencyRates < ActiveRecord::Migration[7.1]
  def change
    create_table :currency_rates do |t|
      t.string :currency_code, null: false
      t.string :base_currency, null: false, default: "USD"
      t.decimal :rate_to_base, precision: 18, scale: 10, null: false
      t.datetime :fetched_at
      t.string :source

      t.timestamps
    end

    add_index :currency_rates, :currency_code, unique: true
  end
end
