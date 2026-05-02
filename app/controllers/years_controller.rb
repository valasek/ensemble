class YearsController < ApplicationController
  before_action :set_assembly

  # GET /assemblies/:assembly_id/years
  def index
    @years = @assembly.member_of_assemblies.distinct.pluck(:year).sort.reverse

    members_by_year = @assembly.member_of_assemblies
                               .where(year: @years)
                               .group(:year)
                               .count("DISTINCT member_id")

    performances_by_year = @assembly.performances
                                    .group("strftime('%Y', date)")
                                    .count
                                    .transform_keys(&:to_i)

    @year_stats = @years.index_with do |year|
      {
        members: members_by_year[year] || 0,
        performances: performances_by_year[year] || 0
      }
    end
  end

  # GET /assemblies/:assembly_id/years/:id
  def show
    @year = params[:id].to_i
    unless @assembly.member_of_assemblies.where(year: @year).exists?
      redirect_to assembly_years_path(@assembly), alert: "Rok nebol nájdený." and return
    end

    @assembly_year = @assembly.assembly_years.find_by(year: @year)
    member_ids = @assembly.member_of_assemblies.where(year: @year).pluck(:member_id)
    @members = @assembly.members.where(id: member_ids).sorted_by_name
    @performances = @assembly.performances.where("strftime('%Y', date) = ?", @year.to_s).order(date: :asc)
  end

  private

  def set_assembly
    @assembly = Assembly.find(params[:assembly_id])
  end
end
