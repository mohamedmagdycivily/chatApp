# app/services/redis_service.rb
module RedisService
  def redis
    Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6379))
  end

  def app_exists_in_redis?(token)
    redis_connection = redis
    redis_connection.hexists('apps', token)
  ensure
    redis_connection.close if redis_connection
  end

  def update_and_get_chat_count(token)
    redis_connection = redis
    updated_count = redis_connection.hincrby('apps', token, 1)
    puts "updated_count Result: #{updated_count.inspect}"
    updated_count.to_i
  ensure
    redis_connection.close if redis_connection
  end

  def create_new_app_in_redis(token)
    redis_connection = redis
    result = redis_connection.hsetnx('apps', token, 0)
    result ? 1 : 0 # Convert true/false to 1/0
  ensure
    redis_connection.close if redis_connection
  end

  def create_new_chat_in_redis(token)
    redis_connection = redis
    result = redis_connection.hsetnx('chats', token, 0)
    result ? 1 : 0 # Convert true/false to 1/0
  ensure
    redis_connection.close if redis_connection
  end

  def update_and_get_message_count(token)
    redis_connection = redis
    updated_message_count = redis_connection.hincrby('chats', token, 1)
    puts "updated_message_count Result: #{updated_message_count.inspect}"
    updated_message_count.to_i
  ensure
    redis_connection.close if redis_connection
  end
end
