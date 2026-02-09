class Avo::Resources::Performance < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :date, as: :date
    field :name, as: :text
    field :location, as: :text
    field :description, as: :trix
    field :assembly_id, as: :number
  end
end
