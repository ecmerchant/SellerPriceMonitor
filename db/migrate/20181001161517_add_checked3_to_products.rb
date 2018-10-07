class AddChecked3ToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :checked3, :boolean
  end
end
