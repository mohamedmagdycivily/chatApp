class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.bigint :message_number
      t.references :chat, null: false, foreign_key: true
      t.string :content, null: false

      t.timestamps
    end
    
    # # Remove the default index on chat_id
    # remove_index :messages, :chat_id
    
    # Add a composite index on chat_id and message_number
    # add_index :messages, [:chat_id, :message_number]
  end
end
