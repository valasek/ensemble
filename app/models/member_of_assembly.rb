class MemberOfAssembly < ApplicationRecord
  # acts_as_tenant(:assembly)

  belongs_to :member
  belongs_to :assembly

  validates :year, presence: true, numericality: { only_integer: true }
  validates :member_id, uniqueness: { scope: [ :assembly_id, :year, :group ], message: "already in this assembly and group for this year and group" }

    def avo_title
    "#{member.name}, #{year}, #{group}"
    end

    def self.ransackable_attributes(auth_object = nil)
      [ "year", "group", "member_id", "assembly_id" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "member", "assembly" ]
    end
end
