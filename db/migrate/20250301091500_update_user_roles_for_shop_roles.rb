class UpdateUserRolesForShopRoles < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE users
      SET role = 2
      WHERE role = 1
    SQL
  end

  def down
    execute <<~SQL
      UPDATE users
      SET role = 1
      WHERE role = 2
    SQL
  end
end
