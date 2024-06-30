class Api::V1::MessagesController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :verify_authenticity_token
      include RedisService
      include Elasticsearch::Model
      include Elasticsearch::Model::Callbacks
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
        #indexing the message
        index_chat_message(params[:token], chat.chat_number, message_number, message_params)

        AppJob.perform_later(chat.id, message_number, "create_message", message_params)

        # Respond to the request indicating success
        render json: { message: "Chat creation queued successfully" }, status: :ok
        
      end

      def search
        # Parameters: {"page"=>"1", "per_page"=>"10", "query"=>"Hello", "app_id"=>"11", "chat_id"=>"1"}
        token = params[:token]
        chat_number = params[:chat_number]
        page = params[:page].to_i || 1
        per_page = params[:per_page].to_i || 10 
        query = params[:query]
        puts "token Result: #{token.inspect}"
        puts "chat_number Result: #{chat_number.inspect}"
        puts "query Result: #{query.inspect}"
        # Perform Elasticsearch query
        @messages = search_messages(token, chat_number, query , page, per_page)
    
        # Respond with paginated messages
        render json: { messages: @messages }, status: :ok
      end

      private

      def index_chat_message(app_token, chat_number, message_number, content)
        client = Elasticsearch::Model.client
        client.index index: 'chat_messages', body: {
          app_token: app_token,
          chat_number: chat_number,
          message_number: message_number,
          content: content
        }
      end

      def search_messages(token, chat_number, query, page, per_page)
        puts "token Result: #{token.inspect}"
        puts "chat_number Result: #{chat_number.inspect}"
        puts "query Result: #{query.inspect}"

        return [] if token.blank? || chat_number.blank? || query.blank?
        client = Elasticsearch::Model.client
        puts "query Result: #{query.inspect}"
        response = client.search(index: 'chat_messages', body: {
          query: {
            bool: {
              must: [
                { match: { "content.content": query } },
                { match: { app_token: token } },
                { match: { chat_number: chat_number } }
              ]
            }
          },
          from: (page - 1) * per_page,
          size: per_page
        })
        puts "response Result: #{response.inspect}"
    
        hits = response['hits']['hits'].map { |hit| hit['_source'] }
        hits
      end
    
    end
