class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :check_action, only: :index
  before_action :crawler_posts, only: [:index]

  # GET /posts
  # GET /posts.json
  def index
    @q = Post.ransack(params[:q] = {tag_cont: params[:action_name] || "tin-moi-nhat"})
    @posts = @q.result.order_by_created_at.page params[:page]
    # expires_in 2.minutes
    fresh_when last_modified: @posts.maximum(:updated_at), etag: @posts
    # fresh_when etag: @posts
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    # expires_in 2.minutes
    fresh_when etag: @post, last_modified: @post.updated_at
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:link, :title, :category_id, :permalink, :description, :image)
    end

    def crawler_posts
      if Post.blank? || Post.last.created_at + 4.hours < Time.now
        if params[:action_name]
          Crawler.delay.crawl_by_action(params[:action_name])
        else
          Crawler.delay.crawl_barch
        end
      end
    end
    def check_action
      if params[:action_name] && !Crawler::VALID_ACTION.include?(params[:action_name])
        redirect_to root_path
      end
    end
end
