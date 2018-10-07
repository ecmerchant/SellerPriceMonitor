class AddRoomid3ToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :roomid3, :string
  end
end
