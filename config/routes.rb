Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :apps, only: [:index, :create]

      get '/apps/:token', to: 'apps#show', as: 'show_by_token'
      patch '/apps/:token', to: 'apps#update', as: 'update_by_token'

      # New endpoints for chats
      get '/apps/:token/chats', to: 'chats#index', as: 'application_chats'
      get '/apps/:token/chats/:chat_number', to: 'chats#show', as: 'application_chat'
      post '/apps/:token/chats', to: 'chats#create', as: 'create_application_chat'

      # New endpoints for messages
      get '/apps/:token/chats/:chat_number/messages', to: 'messages#index', as: 'chat_messages'
      get '/apps/:token/chats/:chat_number/messages/:message_number', to: 'messages#show', as: 'chat_message'
      post '/apps/:token/chats/:chat_number/messages', to: 'messages#create', as: 'create_chat_message'
      patch '/apps/:token/chats/:chat_number/messages/:message_number', to: 'messages#update', as: 'update_chat_message'
      get '/apps/:token/chats/:chat_number/messages/search', to: 'messages#search', as: 'search_chat_messages'
      
    end
  end

  Rails.logger.debug Rails.application.routes.routes.map(&:path).join("\n")
end
