class TrainingsController < ApplicationController
  require 'sidekiq/api'
  require 'google/apis/calendar_v3'
  require 'googleauth'
  include ClientListConcern
  before_action :find_training, only: %i[show edit update cancel destroy]
  before_action :authenticate_user!
  # protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, only: %i[join_clients]

  def index

    @training = Training.where(user_id: current_user.id).map do |training|
      {
        name:     Client.find_by(id: training.client_id).full_name,
        training: training
      }
    end
  end

  def show
    @name = Client.find_by(id: @training.client_id).full_name
    @sets = kit_constructor
  end

  def new
    @clients = current_user.clients
    @training = current_user.trainings.build
    # todo: parse and set to calendar input
    date = params[:date][0...10]
    @day = date[8].to_i == 0 ? date[9] : date[8..9]
    @month = date[5].to_i == 0 ? date[6] : date[5..6]
    @year = date[0..3]
  end

  def join_clients
    if params[:clients] && params[:clients].present?
      @clients = current_user.clients.select do|client|
        JSON.parse(params[:clients]).include?(client.id.to_s)
      end
    end
    render layout: false
  end

  def client_list
    current_user.clients.map do |client|
    # Client.where(user_id: user).map do |client|
      [client.first_name + ' ' + client.second_name, client.id]
    end
  end

  def create
    @training = current_user.trainings.build(training_params)
    if @training.save
      client = Signet::OAuth2::Client.new(client_options)
      client.update!(session[:authorization])
      calendar_id = Calendar.find_by(user_id: current_user.id).calendar_id
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client
      start_time = @training.time
      end_time = start_time + 2.hours
      summary = Client.find_by(id: @training.client_id).full_name
      event = Google::Apis::CalendarV3::Event.new({
                                                      id: 'training' + @training.id.to_s,
                                                      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: (start_time - 3.hours).to_datetime.rfc3339),
                                                      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: (end_time - 3.hours).to_datetime.rfc3339),
                                                      summary: summary,
                                                      description: @training.description
                                                  })
      service.insert_event(calendar_id, event)
      TrainingsHelper::BackgroundProccess.create_background_proc(@training.id) unless @training.status == :complete
      redirect_to edit_training_path(@training)
    else
      render 'new'
    end
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)
    retry
  end

  def edit
    @list = client_list
    @name = name(@training)
    @sets = sets(@training, current_user)
  end

  def update
    @training.update(status: :planned)
    if @training.update(training_params)
      client = Signet::OAuth2::Client.new(client_options)
      client.update!(session[:authorization])
      calendar_id = Calendar.find_by(user_id: current_user.id).calendar_id
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client
      start_time = @training.time
      end_time = start_time + 2.hours
      summary = Client.find_by(id: @training.client_id).full_name
      event = Google::Apis::CalendarV3::Event.new({
                                                      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: (start_time - 3.hours).to_datetime.rfc3339),
                                                      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: (end_time - 3.hours).to_datetime.rfc3339),
                                                      summary: summary,
                                                      description: @training.description
                                                  })
      service.patch_event(calendar_id, 'training' + @training.id.to_s, event)
      if @training.status == :planned
        TrainingsHelper::BackgroundProccess.delete_background_proc(@training.id)
        TrainingsHelper::BackgroundProccess.create_background_proc(@training.id)
      end
      @training.status = :complete if @training.time.to_f < DateTime.now.to_f
      @training.save!
      redirect_to training_path
    else
      render 'edit'
    end
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)
    retry
  end

  def cancel
    @training.update(status: :canceled)
  end

  def destroy
    client = Signet::OAuth2::Client.new(client_options)
    client.update!(session[:authorization])
    calendar_id = Calendar.find_by(user_id: current_user.id).calendar_id
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    service.delete_event(calendar_id, 'training' + @training.id.to_s)
    TrainingsHelper::BackgroundProccess.delete_background_proc(@training.id)
    @training.destroy
    redirect_to calendar_index_path
  rescue Google::Apis::AuthorizationError
    response = client.refresh!
    session[:authorization] = session[:authorization].merge(response)
    retry
  end

  private

  def find_training
    @training = Training.find(params[:id])
  end

  def training_params
    params[:training][:price] = Client.find(params[:training][:client_id]).price if params[:training][:price].empty?
    params.require(:training).slice(:time, :price, :description, :client_id, :status, :cancel,
                                    'time(1i)', 'time(2i)', 'time(3i)', 'time(4i)', 'time(5i)').permit!
  end

  def create_background_proc(training_id)
    training = Training.find(training_id)
    tmp = WithdrawPaymentJob.perform_at((training.time + 2.hours).to_f,
                                        { :client_id => training.client_id,
                                          :user_id => training.user_id,
                                          :time => training.time + 2.hours,
                                          :price => training.price,
                                          :training_id => training.id
                                        }.to_json)
    job = Job.new(GUID: tmp, training_id: training.id)
    job.save!
  end

  def kit_constructor
    sets = Kit.where(training_id: @training.id, user_id: current_user.id).map do |kit|
      {
        exercises: Exercise.where(kit_id: kit.id, user_id: current_user.id),
        kit:       kit
      }
    end
    sets.each do |kit|
      tmp_kit = kit[:exercises].map do |exe|
        {name: ExerciseType.find_by(id: exe.exercise_type_id).name, exe: exe}
      end
      kit[:exercises] = tmp_kit
    end
    sets
  end

  def client_options
    {
        client_id: Rails.application.secrets.google_client_id,
        client_secret: Rails.application.secrets.google_client_secret,
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        user_id: current_user.id,
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
        redirect_uri: callback_url
    }
  end
end
