class AssembliesController < ApplicationController
  # skip_before_action :set_tenant, only: [ :index, :show, :new, :create ]
  before_action :set_assembly, only: %i[ show edit update destroy ]

  def index
    @assemblies = Assembly.all
  end

  def show
    @assembly = Assembly.find(params[:id])
    @latest_performances = @assembly.performances.order(date: :desc).limit(10)
    @latest_members = @assembly.members.order(created_at: :desc).limit(10)
  end

  def new
    @assembly = Assembly.new
  end

  def create
    @assembly = Assembly.new(assembly_params)

    if @assembly.save
      # Optionally assign current user to this assembly
      current_user.update(assembly: @assembly) if current_user.assembly.nil?
      redirect_to @assembly, notice: "Assembly was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @assembly.update(assembly_params)
      redirect_to @assembly, notice: "Assembly was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assembly.destroy!
    redirect_to assemblies_url, notice: "Assembly was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_assembly
      @assembly = Assembly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def assembly_params
      params.require(:assembly).permit(:name, :production)
    end
end
