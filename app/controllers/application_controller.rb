require_relative '../dynamo_db/connection'

Dir[File.dirname(__FILE__) + "/../models/*.rb"].each do |f|
  load f unless f.end_with?('user.rb')
end

class ApplicationController < ActionController::Base
  include ApplicationHelper, Connection
  layout "application"

  rescue_from CanCan::AccessDenied do
    redirect_to root_path, :alert => t("forem.access_denied")
  end

  def current_ability
    Ability.new(forem_user)
  end

  # Kaminari defaults page_method_name to :page, will_paginate always uses
  # :page
  def pagination_method
    defined?(Kaminari) ? Kaminari.config.page_method_name : :page
  end

  # Kaminari defaults param_name to :page, will_paginate always uses :page
  def pagination_param
    defined?(Kaminari) ? Kaminari.config.param_name : :page
  end
  helper_method :pagination_param

  private

  def authenticate_forem_user
    if !forem_user
      session["user_return_to"] = request.fullpath
      flash.alert = t("forem.errors.not_signed_in")
      devise_route = "new_#{Forem.user_class.to_s.underscore}_session_path"
      sign_in_path = Forem.sign_in_path ||
          (main_app.respond_to?(devise_route) && main_app.send(devise_route)) ||
          (main_app.respond_to?(:sign_in_path) && main_app.send(:sign_in_path))
      if sign_in_path
        redirect_to sign_in_path
      else
        raise "Forem could not determine the sign in path for your application. Please do one of these things:

1) Define sign_in_path in the config/routes.rb of your application like this:

or; 2) Set Forem.sign_in_path to a String value that represents the location of your sign in form, such as '/users/sign_in'."
      end
    end
  end

  def forem_admin?
    forem_user && forem_user.forem_admin?
  end
  helper_method :forem_admin?

  def forem_admin_or_moderator?(forum)
    forem_user && (forem_user.forem_admin? || forum.moderator?(forem_user))
  end
  helper_method :forem_admin_or_moderator?

  def forem_user
    current_user
  end
  helper_method :forem_user

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def attributes(target, additions = [], exclusions = nil, to_sym = false)
    if target.is_a?(Enumerable)
      target.map { |t| to_hash(t, additions, exclusions, to_sym) }
    else
      to_hash(target, additions, exclusions, to_sym)
    end
  end

  def max_updated_at(target)
    fail "#{target.inspect} is not Enumerable" unless target.is_a?(Enumerable)
    target.map do |t|
      if t.is_a?(Hash)
        updated_at = t['updated_at']
      else
        updated_at = t.attributes['updated_at']
      end
      Time.at(updated_at)
    end.max
  end

  # def view_for(user)
  #   views.find_by(user_id: user.id)
  # end

  # Track when users last viewed topics
  def register_view_by(user, viewable_type, viewable_id)
    return unless user
    view = get('views', {user_id: user.id, id: "#{viewable_type}##{viewable_id}"})
    unless view
      view = View.create(
          user_id: user.id,
          id: "#{viewable_type}##{viewable_id}",
          viewable_id: viewable_id,
          viewable_type: viewable_type)
    end


    # view.increment!('count')
    # increment!(:views_count)
    #
    # # update current_viewed_at if more than 15 minutes ago
    # if view.current_viewed_at.nil?
    #   view.past_viewed_at = view.current_viewed_at = Time.now
    # end
    #
    # # Update the current_viewed_at if it is BEFORE 15 minutes ago.
    # if view.current_viewed_at < 15.minutes.ago
    #   view.past_viewed_at = view.current_viewed_at
    #   view.current_viewed_at = Time.now
    #   view.save
    # end
    view
  end

end
