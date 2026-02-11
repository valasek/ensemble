class UpdateUniqueIndexOnMemberOfAssemblies < ActiveRecord::Migration[8.1]
  def change
    # Remove the old restricted index
    remove_index :member_of_assemblies, [:assembly_id, :member_id, :year], name: "index_member_of_assemblies_on_assembly_member_year"

    # Add the new index that includes :group
    add_index :member_of_assemblies, [:assembly_id, :member_id, :year, :group], unique: true, name: "idx_member_assembly_year_group_uniq"
  end
end
