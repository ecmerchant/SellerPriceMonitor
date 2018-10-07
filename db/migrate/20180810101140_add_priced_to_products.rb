class AddPricedToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :priced, :boolean
  end
end
