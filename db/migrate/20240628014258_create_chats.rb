class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.bigint :chat_number
      t.bigint :message_count, default: 0
      t.references :app, null: false, foreign_key: true

      t.timestamps
    end

    # Add a unique composite index on app_id and chat_number
    add_index :chats, [:app_id, :chat_number], unique: true
  end
end
