class MemberOfAssembly < ApplicationRecord
  # acts_as_tenant(:assembly)

  belongs_to :member, :assembly

  validates :year, presence: true, numericality: { only_integer: true }
  validates :member_id, uniqueness: { scope: [ :assembly_id, :year ] }
end
