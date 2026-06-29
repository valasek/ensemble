class Avo::Resources::PerformanceCategory < Avo::BaseResource
  self.title = :avo_title
  self.search = {
    query: -> {
      query.joins(:performance, :category)
           .ransack(
             performance_name_cont: params[:q],
             category_name_cont: params[:q],
             m: "or"
           ).result(distinct: false)
    }
  }

  def fields
    field :performance, as: :belongs_to, searchable: true
    field :category, as: :belongs_to, searchable: true
  end
end
