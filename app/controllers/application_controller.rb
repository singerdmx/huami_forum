load File.dirname(__FILE__) + '/../dynamo_db/connection.rb'
load File.dirname(__FILE__) + '/../dynamo_db/initializer.rb'
DynamoDatabase::Initializer.load_table_classes

class ApplicationController < ActionController::Base
  include ApplicationHelper, Connection, Viewable
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
    if current_user
      return
    end

    session["user_return_to"] = request.fullpath
    respond_to do |format|
      format.html do
        redirect_to controller: 'devise/sessions', action: 'new', alert: t("forems.errors.not_signed_in")
      end
      format.json do
        render json: {message: 'You are not signed in'}.to_json, status: :unauthorized
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

end
