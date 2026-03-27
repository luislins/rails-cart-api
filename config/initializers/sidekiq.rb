redis_config = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'), read_timeout: 10 }

Sidekiq.configure_server do |config|
  config.redis = redis_config

  config.on(:startup) do
    schedule_file = Rails.root.join('config', 'sidekiq.yml')

    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)[:scheduler][:schedule]
      SidekiqScheduler::Scheduler.instance.rufus_scheduler_options = {}
      Sidekiq.schedule = schedule
    end
  end
end
