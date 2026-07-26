class MemberOfAssembly < ApplicationRecord
  # acts_as_tenant(:assembly)

  belongs_to :member
  belongs_to :assembly

  validates :year, presence: true, numericality: { only_integer: true }
  validates :member_id, uniqueness: { scope: [ :assembly_id, :year ], message: "already in this assembly for this year" }

    def avo_title
    "#{member.name}, #{year}"
    end

    def self.ransackable_attributes(auth_object = nil)
      [ "year", "member_id", "assembly_id" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "member", "assembly" ]
    end
end
