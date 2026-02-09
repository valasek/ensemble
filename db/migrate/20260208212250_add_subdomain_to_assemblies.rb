class AddSubdomainToAssemblies < ActiveRecord::Migration[8.1]
  def change
    add_column :assemblies, :subdomain, :string
    add_index :assemblies, :subdomain, unique: true
  end
end
