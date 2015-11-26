class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :link
      t.text :title
      t.integer :category_id
      t.string :permalink
      

      t.string :image
      t.text :description
      t.text   :content

      t.timestamps null: false
    end
  end
end
