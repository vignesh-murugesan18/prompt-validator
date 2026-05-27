class CreatePromptTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_templates do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :category, null: false
      t.text :description
      t.text :prompt_text, null: false
      t.string :ai_model
      t.boolean :web_search_default, null: false, default: false
      t.boolean :public, null: false, default: true

      t.timestamps
    end

    add_index :prompt_templates, :slug, unique: true
    add_index :prompt_templates, :category
    add_index :prompt_templates, :public
  end
end
