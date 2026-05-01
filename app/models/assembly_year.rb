class AssemblyYear < ApplicationRecord
  belongs_to :assembly

  has_rich_text :description

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900 }
  validates :year, uniqueness: { scope: :assembly_id, message: "already exists for this assembly" }

  scope :sorted, -> { order(year: :desc) }

  def avo_title
    "#{assembly&.name} – #{year}"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "year", "assembly_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "assembly" ]
  end
end
