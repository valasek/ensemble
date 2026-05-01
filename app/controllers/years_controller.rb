class YearsController < ApplicationController
  before_action :set_assembly

  # GET /assemblies/:assembly_id/years
  def index
    @years = @assembly.member_of_assemblies.distinct.pluck(:year).sort.reverse
  end

  # GET /assemblies/:assembly_id/years/:id
  def show
    @year = params[:id].to_i
    unless @assembly.member_of_assemblies.where(year: @year).exists?
      redirect_to assembly_years_path(@assembly), alert: "Rok nebol nájdený." and return
    end
  end

  private

  def set_assembly
    @assembly = Assembly.find(params[:assembly_id])
  end
end
