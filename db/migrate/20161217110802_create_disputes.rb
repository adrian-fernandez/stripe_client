class CreateDisputes < ActiveRecord::Migration
  def change
    # Create as a copy of 'charges' table
    create_table :disputes do |table|
      Charge.columns.each do |column|
        next if column.name == "id"   # already created by create_table
        table.send(column.type.to_sym, column.name.to_sym,  :null => column.null, 
          :limit => column.limit, :default => column.default, :scale => column.scale,
          :precision => column.precision)
      end
    end
  end
end
