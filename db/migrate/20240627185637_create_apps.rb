class CreateApps < ActiveRecord::Migration[7.1]
  def change
    create_table :apps do |t|
      t.bigint :token, null: false
      t.string :name, null: false
      t.integer :chat_count, default: 0

      t.timestamps
    end

    add_index :apps, :token, unique: true
  end
end
