class MailsController < ApplicationController

  before_filter :authenticate_forem_user

  def index
    @is_self = true
    @is_mails_page = true
    render '/profiles/show'
  end

end
