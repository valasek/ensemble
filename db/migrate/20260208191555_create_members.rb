class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :name
      t.references :assembly, null: false, foreign_key: true

      t.timestamps
    end

    add_index :members, [ :assembly_id, :name ]
  end
end
