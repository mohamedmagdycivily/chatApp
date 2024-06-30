# Run migrations twice to ensure they are applied correctly
rails db:create && rails db:migrate

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Start the Rails server
rails s -p 3000 -b '0.0.0.0'
