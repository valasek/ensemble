class CreateMemberOfAssemblies < ActiveRecord::Migration[8.1]
  def change
    create_table :member_of_assemblies do |t|
      t.references :member, null: false, foreign_key: true
      t.integer :year
      t.references :assembly, null: false, foreign_key: true

      t.timestamps
    end

    add_index :member_of_assemblies, [ :assembly_id, :member_id, :year ],
              unique: true,
              name: 'index_member_of_assemblies_on_assembly_member_year'
  end
end
