class AddIsFeaturedToPerformances < ActiveRecord::Migration[8.1]
  def change
    add_column :performances, :is_featured, :boolean, default: false, null: false
  end
end
