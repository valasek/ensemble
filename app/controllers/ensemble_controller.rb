class EnsembleController < ApplicationController
  def home
    # @assemblies = Assembly.order(:name)
    @assembly = Assembly.first
    redirect_to assembly_path(@assembly) if @assembly.present?
  end
end
