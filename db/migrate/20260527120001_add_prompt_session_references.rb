class AddPromptSessionReferences < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:prompt_analyses, :prompt_session_id)
      add_reference :prompt_analyses, :prompt_session, null: true, foreign_key: true
    end

    unless column_exists?(:prompt_experiments, :prompt_session_id)
      add_reference :prompt_experiments, :prompt_session, null: true, foreign_key: true
    end

    backfill_prompt_sessions if table_exists?(:prompt_sessions) && column_exists?(:prompt_analyses, :visitor_token)
  end

  def down
    remove_reference :prompt_experiments, :prompt_session, foreign_key: true if column_exists?(:prompt_experiments, :prompt_session_id)
    remove_reference :prompt_analyses, :prompt_session, foreign_key: true if column_exists?(:prompt_analyses, :prompt_session_id)
  end

  private

  def backfill_prompt_sessions
    say_with_time "Backfilling prompt sessions from visitor_token" do
      execute(<<~SQL.squish)
        INSERT INTO prompt_sessions (visitor_token, last_activity_at, created_at, updated_at)
        SELECT DISTINCT visitor_token, MAX(updated_at), NOW(), NOW()
        FROM prompt_analyses
        WHERE visitor_token IS NOT NULL AND visitor_token != ''
        GROUP BY visitor_token
        ON CONFLICT (visitor_token) DO NOTHING
      SQL

      execute(<<~SQL.squish)
        UPDATE prompt_analyses AS pa
        SET prompt_session_id = ps.id
        FROM prompt_sessions AS ps
        WHERE pa.visitor_token = ps.visitor_token
          AND pa.prompt_session_id IS NULL
      SQL
    end
  end
end
