class AddChecked2ToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :checked2, :boolean
  end
end
