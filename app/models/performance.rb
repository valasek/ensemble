class Performance < ApplicationRecord
  acts_as_tenant(:assembly)

  has_rich_text :description

  validates :name, :date, presence: true
end
