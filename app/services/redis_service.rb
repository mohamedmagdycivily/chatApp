# app/services/redis_service.rb
module RedisService
  def app_exists_in_redis?(token)
    redis = Redis.new
    redis.hexists('apps', token)
  ensure
    redis.close if redis
  end

  def update_and_get_chat_count(token)
    redis = Redis.new
    #new connection to avoid Failed to update chat count: stream closed in another thread 
    # you should use REDIS_POOL instead
    updated_count = redis.hincrby('apps', token, 1)
    puts "updated_count Result: #{updated_count.inspect}"
    updated_count.to_i
  ensure
    redis.close if redis
  end

  def create_new_app_in_redis(token)
    redis = Redis.new
    # Use HSETNX to set the field only if it does not already exist
    result = redis.hsetnx('apps', token, 0)
    result ? 1 : 0 # Convert true/false to 1/0
  ensure
    redis.close if redis
  end

  def create_new_chat_in_redis(token)
    redis = Redis.new
    # Use HSETNX to set the field only if it does not already exist
    result = redis.hsetnx('chats', token, 0)
    result ? 1 : 0 # Convert true/false to 1/0
  ensure
    redis.close if redis
  end

  def update_and_get_message_count(token)
    redis = Redis.new
    #new connection to avoid Failed to update chat count: stream closed in another thread 
    # you should use REDIS_POOL instead
    updated_message_count = redis.hincrby('chats', token, 1)
    puts "updated_message_count Result: #{updated_message_count.inspect}"
    updated_message_count.to_i
  ensure
    redis.close if redis
  end
  
end
