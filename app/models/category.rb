class Category < ApplicationRecord
  belongs_to :assembly
  has_many :performance_categories, dependent: :destroy
  has_many :performances, through: :performance_categories

  validates :name, presence: true, uniqueness: { scope: :assembly_id }

  def avo_title
    name
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "assembly_id", "name" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "assembly", "performance_categories", "performances" ]
  end
end
