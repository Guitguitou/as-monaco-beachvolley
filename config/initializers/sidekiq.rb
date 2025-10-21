require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq/cron'

# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
    network_timeout: 5,
    pool_timeout: 5
  }

  # Sidekiq Unique Jobs configuration
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)

  # Load cron jobs from schedule file
  schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')
  
  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    Sidekiq::Cron::Job.load_from_hash!(schedule) if schedule
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
    network_timeout: 5,
    pool_timeout: 5
  }

  # Sidekiq Unique Jobs configuration
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end



