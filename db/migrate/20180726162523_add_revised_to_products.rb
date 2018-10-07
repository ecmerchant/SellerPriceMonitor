class AddRevisedToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :revised, :boolean
    add_column :products, :revise_val, :float
  end
end
