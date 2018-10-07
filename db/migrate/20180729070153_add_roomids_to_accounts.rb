class AddRoomidsToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :room_id3, :string
    add_column :accounts, :room_id4, :string
  end
end
