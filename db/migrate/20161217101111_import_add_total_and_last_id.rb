class ImportAddTotalAndLastId < ActiveRecord::Migration
  def change
    add_column :imports, :imported_count, :integer, default: 0
    add_column :imports, :total_count, :integer, default: 0
    add_column :imports, :last_id, :string, default: ''
  end
end
