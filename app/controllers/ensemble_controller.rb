class EnsembleController < ApplicationController
  def home
    @assemblies = Assembly.order(:name)
  end
end
