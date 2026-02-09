class Member < ApplicationRecord
  acts_as_tenant(:assembly)

  has_many :member_of_assemblies, dependent: :destroy

  validates :name, presence: true
  validates_uniqueness_to_tenant :name
end
