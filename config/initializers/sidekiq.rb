require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  # accepts :expiration (optional)
  config.redis = {
     url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}"
   }
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end

Sidekiq.configure_server do |config|
  # accepts :expiration (optional)
  config.redis = {
      url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}"
  }
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes

  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes
end
