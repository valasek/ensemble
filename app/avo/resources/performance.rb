class Avo::Resources::Performance < Avo::BaseResource
  self.includes = [ :assembly, :categories ]
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result(distinct: false) }
  }

  def fields
    # field :id, as: :id
    field :date, as: :date
    field :end_date, as: :date
    field :name, as: :text
    field :location, as: :text
    field :is_featured, as: :boolean
    field :categories,
          as: :has_many,
          through: :performance_categories
    field :description, as: :trix
    field :assembly, as: :belongs_to
  end
end
