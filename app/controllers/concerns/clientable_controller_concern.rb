module ClientableControllerConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client, only: [:new, :create, :index]
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end
end