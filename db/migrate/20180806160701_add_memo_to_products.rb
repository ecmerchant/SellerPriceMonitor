class AddMemoToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :memo, :string
  end
end
