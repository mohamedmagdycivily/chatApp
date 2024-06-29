class Api::V1::AppsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      include RedisService
      # GET /api/v1/apps
      def index
        @apps = App.all
        render json: @apps.as_json(only: [:token, :name, :chat_count])
      end

      # GET /api/v1/apps/:token
      def show
        # @app = App.find_by(token: params[:token])
        @app = App.where(token: params[:token])
        if @app
          render json: @app.as_json(only: [:token, :name, :chat_count])
        else
          render json: { error: 'App not found' }, status: :not_found
        end
      end

      # PATCH /api/v1/apps/:token
      def update
        @app = App.find_by(token: params[:token])
        if @app&.update(app_params)
          render json: @app.as_json(only: [:token, :name, :chat_count])
        else
          render json: { error: 'App not found or update failed' }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/apps
      def create
        @app = App.new(app_params)
      
        loop do
          @app.token = generate_unique_token
          prefixed_token = "a_t_#{@app.token}"
          # Check if the token does not already exist in Redis
          if create_new_app_in_redis(prefixed_token) == 1
            if @app.save
              render json: { token: @app.token }, status: :created
              return
            else
              render json: @app.errors, status: :unprocessable_entity
              return
            end
          end
        end
      end
      

      private

      def app_params
        # If the parameters are nested under 'app', use them; otherwise, use the top-level parameters
        params_to_use = params[:app] || params
        params_to_use.permit(:name)
      end

      def generate_unique_token
        loop do
          length = rand(6..10)
          token = rand(10**(length-1)..10**length - 1)
          prefixed_token = "a_t_#{token}"
          puts "checking prefixed_token exist in redis: #{prefixed_token.inspect}"
          break token unless app_exists_in_redis?(prefixed_token)
        end
      end
      

      def self.find_app_by_token(token)
        app = App.where(token: token).select(:id).first
        puts "App Result: #{app.inspect}"
        unless app
          return { error: "There is no app", status: :not_found }
        end
        { app: app, status: :ok }
      end

    end