class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :email, as: :text
    field :provider, as: :text
    field :uid, as: :text
    field :assembly_id, as: :number
    field :assembly, as: :belongs_to
  end
end
