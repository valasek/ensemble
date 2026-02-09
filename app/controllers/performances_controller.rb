class PerformancesController < ApplicationController
  before_action :set_performance, only: %i[ show edit update destroy ]
  before_action :set_assembly

  # GET /performances
  def index
    @performances = @assembly.performances.order(date: :desc)
  end

  # GET /performances/1
  def show
  end

  # GET /performances/new
  def new
    @performance = @assembly.performances.build
  end

  # GET /performances/1/edit
  def edit
  end

  # POST /performances
  def create
    @performance = @assembly.performances.build(performance_params)

    if @performance.save
      redirect_to @performance, notice: "Performance was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /performances/1
  def update
    if @performance.update(performance_params)
      redirect_to @performance, notice: "Performance was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /performances/1
  def destroy
    @performance.destroy!
    redirect_to performances_url, notice: "Performance was successfully destroyed.", status: :see_other
  end

  private
    def set_performance
      @performance = @assembly.performances.find(params[:id])
    end

    def set_assembly
      @assembly = Assembly.find(params[:assembly_id])
    end

    def performance_params
      params.require(:performance).permit(:date, :name, :location, :description)
    end
end
