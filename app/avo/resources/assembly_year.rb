class Avo::Resources::AssemblyYear < Avo::BaseResource
  self.includes = [ :assembly ]
  self.search = {
    query: -> { query.ransack(year_eq: params[:q]).result(distinct: false) }
  }

  def fields
    field :year, as: :number
    field :description, as: :trix
    field :assembly, as: :belongs_to
  end
end
