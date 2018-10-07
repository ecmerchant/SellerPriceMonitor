class AddUsedcheckToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :used_check, :boolean
  end
end
