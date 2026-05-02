class AddEndDateToPerformances < ActiveRecord::Migration[8.1]
  def change
    add_column :performances, :end_date, :date
  end
end
