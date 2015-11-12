class ProfilesController < ApplicationController

  before_filter :authenticate_forem_user
  before_filter :find_profile

  def show
  end

  private

  def find_profile
    flash.delete(:success)
    flash.delete(:error)
    @profile = Profile.find(params[:id])
  end

end
