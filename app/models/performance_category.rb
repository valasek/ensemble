class PerformanceCategory < ApplicationRecord
  belongs_to :performance
  belongs_to :category

  validates :performance_id, uniqueness: { scope: :category_id }

  def avo_title
    "#{performance&.name} - #{category&.name}"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "category_id", "performance_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "category", "performance" ]
  end
end
