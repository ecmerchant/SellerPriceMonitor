class AddIsFbaToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :is_fba, :boolean
  end
end
