class CreateAssemblyYears < ActiveRecord::Migration[8.1]
  def change
    create_table :assembly_years do |t|
      t.references :assembly, null: false, foreign_key: true
      t.integer :year, null: false

      t.timestamps
    end

    add_index :assembly_years, [ :assembly_id, :year ], unique: true
  end
end
