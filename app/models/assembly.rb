class Assembly < ApplicationRecord
  has_many :users
  has_many :members, dependent: :destroy
  has_many :member_of_assemblies, dependent: :destroy
  has_many :performances, dependent: :destroy
  has_many :assembly_years, dependent: :destroy

  has_rich_text :production

  before_save { self.subdomain = subdomain.downcase }

  validates :name, presence: true, uniqueness: true
  validates :subdomain,
            presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-z0-9-]+\z/ },
            exclusion: { in: %w[www admin support mail help], message: "%{value} is reserved." }

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "subdomain" ]
  end
end
