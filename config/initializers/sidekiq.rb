# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = {
    url: "redis://#{ENV.fetch('REDIS_HOST', 'localhost')}:#{ENV.fetch('REDIS_PORT', 6379)}/0"
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "redis://#{ENV.fetch('REDIS_HOST', 'localhost')}:#{ENV.fetch('REDIS_PORT', 6379)}/0"
  }
end
