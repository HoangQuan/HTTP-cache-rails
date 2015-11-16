class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.text :link
      t.string :title
      t.integer :category_id
      t.string :permalink

      t.timestamps null: false
    end
  end
end
