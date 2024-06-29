# app/controllers/api/v1/chats_controller.rb
class Api::V1::ChatsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      include RedisService
      # GET /api/v1/apps/:token/chats
      def index
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]
      
        # Fetch chats
        chats = Chat.where(app_id: app.id).select(:chat_number)
        puts "chats Result: #{chats.inspect}"
      
        # Convert the result to an array of hashes to use as_json
        chat_records = chats.map do |chat|
          {
            chat_number: chat.chat_number,
          }
        end
      
        render json: { chats: chat_records.as_json }, status: :ok
      end

      # GET /api/v1/apps/:token/chats/:chat_number
      def show
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]

        # Fetch chats
        chat = Chat.where(app_id: app.id, chat_number: params[:chat_number]).select(:chat_number).first

        unless chat
          render json: { error: "Chat not found" }, status: :not_found
          return
        end

        render json: chat.as_json(only: [:chat_number])
      end

      def create
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]

        # redis
        prefixed_app_token = "a_t_#{params[:token]}"
        updated_count = update_and_get_chat_count(prefixed_app_token)
        prefixed_chat_token = "aid_#{app.id}_cnum_#{updated_count}"
        #ex for  prefixed_chat_token = "aid_44_cnum_63"
        puts "app.id Result: #{app.id.inspect}"
        puts "updated_count Result: #{updated_count.inspect}"
        puts "prefixed_chat_token Result: #{prefixed_chat_token.inspect}"
        create_new_chat_in_redis(prefixed_chat_token)
        
        # Queue the job to create the chat asynchronously
        AppJob.perform_later(app.id, updated_count, "create_chat")
    
        # Respond to the request indicating success
        render json: { message: "Chat creation queued successfully" }, status: :ok
      end
      
      private

end
