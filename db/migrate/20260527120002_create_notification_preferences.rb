class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    return if table_exists?(:notification_preferences)

    create_table :notification_preferences do |t|
      t.references :prompt_session, null: false, foreign_key: true, index: { unique: true }
      t.string :email
      t.string :digest_frequency, null: false, default: "none"
      t.boolean :notify_on_complete, null: false, default: false
      t.string :slack_webhook_url
      t.datetime :last_digest_sent_at

      t.timestamps
    end

    add_index :notification_preferences, :digest_frequency
  end
end
