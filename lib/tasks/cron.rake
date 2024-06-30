# lib/tasks/update_counts.rake
# rake update_counts:apps
# rake update_counts:chats

namespace :update_counts do
    desc 'Fetch chat counts from Redis and bulk update MySQL'
    task :apps => :environment do
      begin
        
        $redis =  Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6379))
        # Assuming you have Redis configured already
  
        # Example: HGETALL apps from Redis
        redis_data = $redis.hgetall('apps')
  
        # Prepare data for bulk insert or update
        current_time = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
        values = []
        redis_data.each do |token, chat_count|
          token_id = token.split('_').last.to_i
          count = chat_count.to_i
          puts "Token: #{token_id}, Chat Count: #{count}"
  
          # Skip records where chat_count is 0
          next if count == 0
  
          values << "(#{token_id}, #{count}, 'defaultName', '#{current_time}', '#{current_time}')"
        end
  
        unless values.empty?
          sql = <<-SQL
            INSERT INTO apps (token, chat_count, name, created_at, updated_at)
            VALUES #{values.join(", ")}
            ON DUPLICATE KEY UPDATE chat_count = VALUES(chat_count);
          SQL
          puts "SQL Query: #{sql}"
  
          # Execute the raw SQL query
          ActiveRecord::Base.connection.execute(sql)
  
          puts "Bulk update completed for #{values.size} records."
        else
          puts "No records to update."
        end
      rescue => e
        puts "An error occurred: #{e.message}"
      end
    end

    task :chats => :environment do
        begin
          $redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6379))
          # Assuming you have Redis configured already
    
          # Example: HGETALL apps from Redis
          redis_data = $redis.hgetall('chats')
    
          # Prepare data for bulk insert or update
          current_time = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
          values = []
          redis_data.each do |token, message_count|
            # "aid_45_cnum_763"
            app_id = token.split('_')[1].to_i
            chat_number = token.split('_')[3].to_i
            message_count = message_count.to_i
    
            # Skip records where message_count is 0
            next if message_count == 0
    
            values << "(#{app_id}, #{chat_number}, #{message_count}, '#{current_time}', '#{current_time}')"
          end
    
          unless values.empty?
            puts "values: #{values}"
            sql = <<-SQL
              INSERT INTO chats ( app_id, chat_number, message_count, created_at, updated_at)
              VALUES #{values.join(", ")}
              ON DUPLICATE KEY UPDATE message_count = VALUES(message_count);
            SQL
            puts "SQL Query: #{sql}"
    
            # Execute the raw SQL query
            ActiveRecord::Base.connection.execute(sql)
    
            puts "Bulk update completed for #{values.size} records."
          else
            puts "No records to update."
          end
        rescue => e
          puts "An error occurred: #{e.message}"
        end
    end
end
  