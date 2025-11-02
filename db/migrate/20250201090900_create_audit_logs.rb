class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.string :action, null: false
      t.text :reason
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :audit_logs, :action
    add_index :audit_logs, [:shop_id, :feature_id, :created_at], name: "index_audit_logs_on_shop_feature_and_timestamp"
  end
end
