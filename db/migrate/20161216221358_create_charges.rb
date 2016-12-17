class CreateCharges < ActiveRecord::Migration
  def change
    create_table :charges do |table|
      table.timestamps
      table.references :import, null: false
      table.jsonb :data, null: false, default: '{}'
    end
  end
end
