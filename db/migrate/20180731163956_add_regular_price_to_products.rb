class AddRegularPriceToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :regular_price, :integer
  end
end
