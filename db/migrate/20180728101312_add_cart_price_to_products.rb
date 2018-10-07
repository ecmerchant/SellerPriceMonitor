class AddCartPriceToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :cart_price, :integer
  end
end
