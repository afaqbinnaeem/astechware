# frozen_string_literal: true

class IntegrationsController < ApplicationController
  def index
    @integrations = IntegrationCatalog.ordered
  end

  def show
    slug = params[:slug].to_s
    integration = IntegrationCatalog.find(slug)
    raise ActionController::RoutingError, "Not Found" if integration.blank?

    @integration = integration
    @slug = slug
  end
end