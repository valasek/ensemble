class AddOmniauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :assembly_id, :integer

    add_index :users, :assembly_id
    add_index :users, [ :provider, :uid ], unique: true
  end
end
