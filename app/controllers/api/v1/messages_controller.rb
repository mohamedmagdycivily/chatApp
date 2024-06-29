class Api::V1::MessagesController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      include RedisService
      # GET /apps/:token/chats/:chat_number/messages
      def index
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]

        # Fetch chats
        chat = Chat.where(app_id: app.id, chat_number: params[:chat_number]).select(:id).first
        puts "chat Result: #{chat.inspect}"
        unless chat
          render json: { error: "Chat not found" }, status: :not_found
          return
        end

        # Fetch messages
        messages = Message.where(chat_id: chat.id).select(:content)
        render json: messages.as_json(only: [:content]), status: :ok
      end

      # GET /apps/:token/chats/:chat_number/messages/:message_number
      def show
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]

        # Fetch chats
        chat = Chat.where(app_id: app.id, chat_number: params[:chat_number]).select(:id).first
        puts "chat Result: #{chat.inspect}"
        unless chat
          render json: { error: "Chat not found" }, status: :not_found
          return
        end

        #fetch messages
        messages = Message.where(chat_id: chat.id, message_number: params[:message_number]).select(:Message_number, :content)
    
        render json: messages.as_json(only: [:Message_number, :content]), status: :ok

      end

      def create
        # Fetch app
        app_result = Api::V1::AppsController.find_app_by_token(params[:token])
        if app_result[:error]
          render json: { error: app_result[:error] }, status: app_result[:status]
          return
        end
        app = app_result[:app]

        # Fetch chats
        chat = Chat.where(app_id: app.id, chat_number: params[:chat_number]).select(:id, :chat_number).first
        puts "chat Result: #{chat.inspect}"
        unless chat
          render json: { error: "Chat not found" }, status: :not_found
          return
        end

        #create message
        # redis
        prefixed_chat_token = "aid_#{app.id}_cnum_#{chat.chat_number}"
        #ex for  prefixed_chat_token = "aid_44_cnum_63"
        message_number = update_and_get_message_count(prefixed_chat_token)

        # Queue the job to create the message asynchronously
        message_params = params.require(:message).permit(:content)
        AppJob.perform_later(chat.id, message_number, "create_message", message_params)

        # Respond to the request indicating success
        render json: { message: "Chat creation queued successfully" }, status: :ok
        
      end

    end
