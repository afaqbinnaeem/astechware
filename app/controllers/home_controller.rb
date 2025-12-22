class HomeController < ApplicationController
  protect_from_forgery except: [:submit_form]

  def index
    @page_title = "A'sTechware Dashboard"
    @page_description = "Landing Page for A'sTechware. Transforming future with technology."
    @page_keywords = "A'sTechware, Best Software House, Best Digital Agency in Pakistan"
    
    # Set Open Graph meta tags for social sharing
    # Using logo.png which matches the navbar logo
    set_meta_tags(
      title: "AI Automations & Custom Software for SMBs | A'sTechware",
      description: "We design and build production-grade AI automations and custom web/mobile platforms from internal ops systems to marketplaces and customer-facing products so businesses can run faster without adding headcount.",
      og: {
        title: "AI Automations & Custom Software for SMBs | A'sTechware",
        description: "We design and build production-grade AI automations and custom web/mobile platforms from internal ops systems to marketplaces and customer-facing products so businesses can run faster without adding headcount.",
        image: image_url('logo.png'),
        url: request.url,
        type: 'website',
        site_name: "A'sTechware"
      },
      twitter: {
        card: 'summary',
        title: "AI Automations & Custom Software for SMBs | A'sTechware",
        description: "We design and build production-grade AI automations and custom web/mobile platforms from internal ops systems to marketplaces and customer-facing products so businesses can run faster without adding headcount.",
        image: image_url('logo.png')
      }
    )
  end

  def submit_form
    @form = Form.new(form_params)
    ContactFormMailer.submit_contact_form(@form).deliver
    redirect_to root_path, notice: "Successfully Submitted Response."
  end

  private def form_params
    params.require(:form).permit(:reason, :name, :email, :company_name, :cover_letter)
  end

  def ourTeam
  end

  def teamDetail
  end
  
  def blog
  end

  def portfolio
  end
end
