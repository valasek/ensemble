class Avo::Resources::MemberOfAssembly < Avo::BaseResource
  self.includes = [ :member, :assembly ]
  self.title = :avo_title
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> {
      query.joins(:member, :assembly)
           .ransack(
             member_name_cont: params[:q],
             group_name_cont: params[:q],
             year_cont: params[:q],
             m: "or"
           ).result(distinct: false)
    }
  }

  def fields
    # field :id, as: :id
    # field :member, as: :belongs_to, searchable: true
    field :member,
          as: :belongs_to,
          attach_scope: -> { query.order(:name) }
    field :year, as: :select, options: (1950..2030).to_a
    field :group, as: :text
    field :assembly, as: :belongs_to, searchable: true
  end
end
