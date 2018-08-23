class KitsController < ApplicationController
  before_action :find_kit, only: %i[show edit update destroy]
  before_action :authenticate_user!
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token

  def index
    @kit = Kit.all
  end

  def show
    @exercises = Exercise.where(kit_id: @kit.id)
    @exes = @exercises.map do |exe|
      {
        name: ExerciseType.find_by(id: exe.exercise_type_id).name,
        exe:  exe
      }
    end
  end

  def new
    create(params[:id])   # Alex, please resolve problem with that method
  end

  def create(id)
    @kit = Kit.new(training_id: id, user_id: current_user.id)
    if @kit.save
      redirect_to edit_kit_path(@kit)
    else
      render 'new'
    end
  end

  def edit
    @id = @kit.id
    render layout: false
  end

  def update
    if @kit.update(kit_params)
      redirect_to kit_path
    else
      render 'edit'
    end
  end

  def destroy
    @kit.destroy
    redirect_to kits_path
  end

  private

  def find_kit
    @kit = Kit.find(params[:id])
  end

  def kit_params
    params.require(:kit).permit(:training_id)
  end
end
