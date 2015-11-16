json.array!(@posts) do |post|
  json.extract! post, :id, :link, :title, :category_id, :permalink
  json.url post_url(post, format: :json)
end
