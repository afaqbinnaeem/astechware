class Form
  attr_accessor :name, :email, :company_name, :cover_letter, :phone, :need_type, :project_type, :reason

  def initialize(form_params)
    @reason = form_params["reason"]
    @name = form_params["name"]
    @email = form_params["email"]
    @company_name = form_params["company_name"]
    @cover_letter = form_params["cover_letter"]
    @phone = form_params["phone"]
    @need_type = form_params["need_type"]
    @project_type = form_params["project_type"]
  end
end
