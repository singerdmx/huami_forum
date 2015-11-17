class UsersController < ApplicationController
  include UsersHelper

  before_filter :authenticate_forem_user, except: [:show]

  def index
    ActiveRecord::Base.transaction do
      all_users = User.all
      users = all_users.map do |u|
        simple_user_hash(u)
      end

      if stale?(etag: users, last_modified: all_users.maximum(:updated_at))
        render json: users
      else
        head :not_modified
      end
    end
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def show
    @profile = Profile.find(User.find(params[:id]).profile.id)
    render 'profiles/show'
  end

end
