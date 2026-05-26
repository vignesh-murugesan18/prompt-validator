class CreateExamplePrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :example_prompts do |t|
      t.string :title, null: false
      t.text :prompt_text, null: false
      t.decimal :score, precision: 3, scale: 1
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :example_prompts, :position
  end
end
