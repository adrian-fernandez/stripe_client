class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |table|
      table.timestamps

      table.string :name
      table.string :stripe_access_token, default: ''
      table.json :stripe_info, default: {}
      table.json :balance, default: {}
      table.datetime :balance_updated_at
    end
  end
end
