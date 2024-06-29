# app/jobs/app_job.rb
class AppJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 5

  def perform(id, number, action, new_param = nil)
    case action
    when 'create_chat'
      create_chat(id, number)
    when 'create_message'
      create_message(id, number, new_param)
    else
      raise ArgumentError, "Unsupported action: #{action}"
    end
  end

  private

  def create_chat(app_id, chat_number)
    # Perform create action
    Chat.create!(app_id: app_id, chat_number: chat_number)
  end

  def create_message(chat_id, message_number, content)
    Message.create!(chat_id: chat_id, message_number: message_number, content: content)
  end


end
