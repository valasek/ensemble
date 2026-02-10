class Performance < ApplicationRecord
  include Meilisearch::Rails

  # acts_as_tenant(:assembly)
  belongs_to :assembly

  has_rich_text :description

  validates :name, :date, presence: true

  meilisearch do
    attribute :name, :date, :description

    attribute :url do
      Rails.application.routes.url_helpers.assembly_performance_path(assembly_id: assembly.id, id: id)
    end

    attribute :assembly_name do
      assembly&.name
    end

    # Convert rich text to plain text for search
    attribute :description do
      if description.is_a?(ActionText::RichText)
        description.to_plain_text
      elsif description.respond_to?(:to_plain_text)
        description.to_plain_text
      else
        description.to_s
      end
    end

    # Add a short excerpt (first 200 characters)
    attribute :excerpt do
      desc_text = if description.respond_to?(:to_plain_text)
        description.to_plain_text
      else
        description.to_s
      end
      desc_text.truncate(200)
    end

    searchable_attributes [ :name, :description, :assembly_name ]
    displayed_attributes [ :name, :date, :description, :excerpt, :assembly_name, :url ]
    filterable_attributes [ :assembly_name ]
    sortable_attributes [ :date, :name ]

    # Custom ranking rules for relevance
    ranking_rules [
      "words",
      "typo",
      "proximity",
      "attribute",
      "sort",
      "exactness",
      "published_at:desc"
    ]

    attributes_to_highlight [ "name", "description" ]
  end
end
