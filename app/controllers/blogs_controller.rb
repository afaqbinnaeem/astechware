class BlogsController < ApplicationController
  def index; end

  def show
    @article = view_context.blog_article_by_slug(params[:slug])
    if @article.blank?
      render "errors/not_found", status: :not_found, layout: "application"
      return
    end
    # Meta and body are rendered in show.html.erb
  end
end
