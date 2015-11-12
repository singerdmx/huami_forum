class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.belongs_to :user, index: true
      t.string :picture
      t.text :signature

      t.timestamps
    end
  end
end
