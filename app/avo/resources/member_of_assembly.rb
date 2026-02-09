class Avo::Resources::MemberOfAssembly < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :member_id, as: :number
    field :year, as: :number
    field :assembly_id, as: :number
  end
end
