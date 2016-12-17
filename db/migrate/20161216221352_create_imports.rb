class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |table|
      table.timestamps
      table.integer :status, null: false, default: 0
      table.integer :imported_type, null: false, default: 0
    end
  end
end
