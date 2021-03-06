require 'set'

class TopicsController < ApplicationController
  helper PostsHelper
  include TopicsHelper, UsersHelper

  before_filter :authenticate_forem_user, except: [:index, :show]
  before_filter :find_topic, only: [:show]
  # before_filter :block_spammers, only: [:create]
  protect_from_forgery except: [:create, :destroy, :update]

  def index
    fail 'params forum_id is undefined!' unless params[:forum_id]
    all_topics = get_topics(params[:forum_id]).map { |t| Topic.new_from_hash(t) }
    topics = attributes(all_topics).map do |t|
      simple_topic_hash(t)
    end

    user_ids = Set.new
    topics.each do |topic|
      user_ids.add(topic['user_id'])
      user_ids.add(topic['last_post_by'])
    end
    mappings = user_mappings(user_ids)
    topics.each do |topic|
      topic['user'] = simple_user_hash(mappings[topic['user_id']])
      topic.delete('user_id')
      topic['last_post_by'] = simple_user_hash(mappings[topic['last_post_by']])
    end

    if stale?(etag: topics, last_modified: max_updated_at(all_topics))
      render json: topics
    else
      head :not_modified
    end
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def show
    register_view_by(current_user, Topic, @topic['id'],
                     {forum: params[:forum_id], id: params[:id]})
    topic = simple_topic_hash(@topic)
    topic['user'] = simple_user_hash(User.find(topic['user_id']))
    render json: topic
  end

  def create
    if current_user.nil?
      render json: {success: true}
      return
    end

    topic = Topic.create(forum: params['forum_id'],
                         category: params['category'],
                         last_post_at: Time.now.to_i,
                         last_post_by: current_user.id,
                         subject: params['subject'],
                         user_id: current_user.id)
    post = Post.create(category: params['category'],
                       forum: params['forum_id'],
                       topic: topic.id,
                       body_text: params['text'],
                       user_id: current_user.id)
    render json: {success: true}
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def destroy
    delete_topic(params[:forum_id], params[:id])
    render json: {success: true}
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  def update
    update_topic(params['forum_id'], params['id'], params['subject'])
    render json: {success: true}
  rescue Exception => e
    Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
    render json: {message: e.to_s}.to_json, status: :internal_server_error
  end

  protected

  def topic_params
    params.require(:topic).permit(:subject, :posts_attributes => [[:text]])
  end

end
