class Form
  attr_accessor :reason, :name, :email, :company_name, :cover_letter

  def initialize(form_params)
    @reason = form_params["reason"]
    @name = form_params["name"]
    @email = form_params["email"]
    @company_name = form_params["company_name"]
    @cover_letter = form_params["cover_letter"]
  end
end
