# Redis configuration
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

# Configure Redis connection
Redis.new(url: redis_url)
