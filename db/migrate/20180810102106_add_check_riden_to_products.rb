class AddCheckRidenToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :check_riden, :boolean
  end
end
