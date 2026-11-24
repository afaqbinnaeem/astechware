class DashboardController < ApplicationController
  before_action :noindex!
  before_action :require_login

  def index
    @visits = Ahoy::Visit.all
  end
end
