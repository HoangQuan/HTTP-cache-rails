class AddTagToPosts < ActiveRecord::Migration
  def change
  	add_column :posts, :tag, :text
  end
end
