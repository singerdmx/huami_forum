class ChangeColumnsInProfile < ActiveRecord::Migration
  def change
    change_column :profiles, :id, :bigint
    change_column :profiles, :user_id, :bigint
  end
end
