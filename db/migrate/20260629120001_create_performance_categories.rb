class CreatePerformanceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_categories do |t|
      t.references :performance, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :performance_categories, [ :performance_id, :category_id ], unique: true
  end
end
