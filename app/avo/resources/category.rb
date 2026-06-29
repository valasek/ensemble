class Avo::Resources::Category < Avo::BaseResource
  self.includes = [ :assembly ]
  self.title = :name
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    field :name, as: :text
    field :assembly, as: :belongs_to, searchable: true
    field :performances,
          as: :has_many,
          through: :performance_categories
  end
end
