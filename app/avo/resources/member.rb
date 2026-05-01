class Avo::Resources::Member < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  self.includes = [ :assembly ]

  def fields
    # field :id, as: :id
    field :name, as: :text
    field :assembly, as: :belongs_to
  end
end
