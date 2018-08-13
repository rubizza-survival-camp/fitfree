class TrainingsController < ApplicationController
  before_action :find_training, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    @training = Training.where(user_id: current_user)
  end

  def show
  end

  def new
    @training = current_user.trainings.build
    @list = []
    Client.all.each do |client|
      each = []
      each << client.first_name + ' ' + client.second_name
      each << client.id
      @list << each
    end
    @kit_list = []
    Kit.all.each do |kit|
      each = []
      each << kit.title
      each << kit.id
      @kit_list << each
    end
  end

  def create
    @training = current_user.trainings.build(training_params)
    if @training.save
      redirect_to calendar_index_path
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @training.update(training_params)
      redirect_to @training
    else
      render 'edit'
    end
  end

  def destroy
    @training.destroy
    redirect_to trainings_path
  end

  private
  def find_training
    @training = Training.find(params[:id])
  end

  def training_params
    params.require(:training).permit(:title, :time, :price,  :description, :client_id, :status)
  end
end
