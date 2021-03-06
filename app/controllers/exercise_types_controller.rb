class ExerciseTypesController < ApplicationController
  before_action :find_exercise_type, only: %i[edit update destroy]
  before_action :authenticate_user!

  def index
    @exercise_types = ExerciseType.all.order(:name).page(params[:page])
    authorize @exercise_types
  end

  def new
    @exercise_type = ExerciseType.new
    authorize @exercise_type
  end

  def create
    @exercise_type = ExerciseType.new(type_params)
    authorize @exercise_type
    if @exercise_type.save
      redirect_to exercise_types_path
    else
      render 'new'
    end
  end

  def edit
    authorize @exercise_type
  end

  def update
    authorize @exercise_type
    if @exercise_type.update(type_params)
      redirect_to exercise_types_path
    else
      render 'edit'
    end
  end

  def destroy
    @exercise_type.destroy
    redirect_to exercise_types_path
  end

  private

  def find_exercise_type
    @exercise_type = ExerciseType.find(params[:id])
  end

  def type_params
    params.require(:exercise_type).permit(:name, :description)
  end
end
