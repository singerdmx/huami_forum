class FavoritesController < ApplicationController
  include Connection

  before_filter :authenticate_forem_user
  protect_from_forgery except: :create

  def index
    favorites = query(UserFavorites, 'user_id = :u', ':u' => current_user.id)
    if stale?(etag: favorites, last_modified: max_updated_at(favorites))
      result = {}
      favorites.group_by { |f| f['type'] }.map do |k, v|
        result[k] = v.map do |h|
          h['favorite']
        end
      end
      render json: result
    else
      head :not_modified
    end
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def create
    UserFavorites.create(user_id: current_user.id, type: params['type'], favorite: params['favorite'])
    render json: {success: true}
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def destroy

  end

end