class MembersController < ApplicationController
  before_action :set_member, only: %i[ show edit update destroy ]
  before_action :set_assembly

  # GET /members
  def index
    @members = @assembly.members.sorted_by_name
  end

  # GET /members/1
  def show
  end

  # GET /members/new
  def new
    @member = @assembly.members.build
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members
  def create
    @member = @assembly.members.build(member_params)

    if @member.save
      redirect_to @member, notice: "Member was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /members/1
  def update
    if @member.update(member_params)
      redirect_to @member, notice: "Member was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /members/1
  def destroy
    @member.destroy!
    redirect_to members_url, notice: "Member was successfully destroyed.", status: :see_other
  end

  private
    def set_member
      @member = @assembly.members.find(params[:id])
    end

    def set_assembly
      @assembly = Assembly.find(params[:assembly_id])
    end

    def member_params
      params.require(:member).permit(:name)
    end
end
