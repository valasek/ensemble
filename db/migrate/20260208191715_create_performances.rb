class CreatePerformances < ActiveRecord::Migration[8.1]
  def change
    create_table :performances do |t|
      t.date :date
      t.string :name
      t.string :location
      t.references :assembly, null: false, foreign_key: true

      t.timestamps
    end

    add_index :performances, [ :assembly_id, :date ]
  end
end
