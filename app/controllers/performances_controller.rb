class PerformancesController < ApplicationController
  before_action :set_assembly
  before_action :set_performance, only: %i[ show edit update destroy ]

  # GET /performances
  def index
    @performances = @assembly.performances
                              .includes(:rich_text_description)
                              .order(date: :desc)
                              .page(params[:page]).per(15)
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
      redirect_to assembly_performance_url(@assembly, @performance), notice: "Performance was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /performances/1
  def update
    if @performance.update(performance_params)
      redirect_to assembly_performance_url(@assembly, @performance), notice: "Performance was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /performances/1
  def destroy
    @performance.destroy!
    redirect_to assembly_performances_url(@assembly), notice: "Performance was successfully destroyed.", status: :see_other
  end

  private
    def set_performance
      @performance = @assembly.performances.find(params[:id])
    end

    def set_assembly
      @assembly = Assembly.find(params[:assembly_id])
    end

    def performance_params
      params.require(:performance).permit(:date, :end_date, :name, :location, :description)
    end
end
