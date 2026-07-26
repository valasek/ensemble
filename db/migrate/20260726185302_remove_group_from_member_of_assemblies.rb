class RemoveGroupFromMemberOfAssemblies < ActiveRecord::Migration[8.1]
  def up
    remove_index :member_of_assemblies, name: "idx_member_assembly_year_group_uniq"

    # Keep one row per (member_id, year) — the lowest id survives, the rest are dropped
    execute <<~SQL
      DELETE FROM member_of_assemblies
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM member_of_assemblies
        GROUP BY member_id, assembly_id, year
      )
    SQL

    remove_column :member_of_assemblies, :group

    add_index :member_of_assemblies, [ :assembly_id, :member_id, :year ],
      unique: true, name: "idx_member_assembly_year_uniq"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "group data and deleted duplicate rows cannot be restored"
  end
end
