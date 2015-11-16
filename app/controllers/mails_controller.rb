class MailsController < ApplicationController

  before_filter :authenticate_forem_user

  def index
  end

end
