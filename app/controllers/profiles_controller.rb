class ProfilesController < ApplicationController

  before_filter :authenticate_forem_user, except: [:show]
  before_filter :find_profile

  def show
    @is_self = current_user.id == @profile.user_id
  end

  private

  def find_profile
    flash.delete(:success)
    flash.delete(:error)
    @profile = Profile.find(params[:id])
  end

end
