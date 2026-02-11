class Member < ApplicationRecord
  include Meilisearch::Rails

  belongs_to :assembly
  has_many :member_of_assemblies, dependent: :destroy

  validates :name, presence: true

  scope :sorted_by_name, -> { order("LOWER(name)") }

  meilisearch do
    attribute :name

    attribute :url do
      if assembly
        Rails.application.routes.url_helpers.assembly_member_path(
          assembly_id: assembly.id,
          id: id
        )
      else
        "#"
      end
    end

    attribute :assembly_name do
      assembly&.name
    end

    searchable_attributes [ :name, :assembly_name ]
    displayed_attributes [ :name, :url, :assembly_name ]
    filterable_attributes [ :assembly_name ]
    sortable_attributes [ :name ]
  end
end
