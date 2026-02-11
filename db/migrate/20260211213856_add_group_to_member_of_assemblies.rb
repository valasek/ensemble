class AddGroupToMemberOfAssemblies < ActiveRecord::Migration[8.1]
  def change
    add_column :member_of_assemblies, :group, :string
  end
end
