module Admin
  class ForumsController < BaseController
    include ForumsHelper, TopicsHelper, PostsHelper, GroupHelper, UsersHelper
    include Connection

    def index
      @forums = attributes(Forum.all, ['moderators'])
      @forum_last_post = {} # key is forum_id, value is Post object
      mappings = user_mappings(@forums.map { |forum| forum['last_post_by'] })
      @forums.each do |forum|
        unless forum['last_post_id'].blank?
          post = simple_post_hash(get(Post, {topic: forum['last_topic_id'], id: forum['last_post_id']}))
          unless mappings.empty?
            user = mappings[post['user_id']]
            post['user'] = user.name
          end
          post['topic'] = simple_topic_hash(get(Topic, {forum: forum['id'], id: post['topic']}))
          @forum_last_post[forum['id']] = post
        end
      end
    end

    def new
      for_new_forum
    end

    def create
      error_msg = ''
      forum_name = params['name']
      description = params['description']
      category = params['forum']['category']
      if forum_name.blank?
        error_msg = 'Forum name can not be empty! '
      end

      if description.blank?
        error_msg += 'Description can not be empty!'
      end

      unless error_msg.blank?
        fail error_msg
      end

      error_msg = nil
      if params[:forum_id].blank?
        c = find_forum_by_name(category, forum_name)
        Rails.logger.info "find_forum_by_name #{category} #{forum_name}: #{c.inspect}"
        unless c.empty?
          error_msg = "Forum '#{forum_name}' already exists"
          fail error_msg
        end
        create_forum(category, forum_name, description, forum_params['moderator_ids'])
        create_successful
      else
        key = {category: category, id: params[:forum_id]}
        forum = Forum.new_from_hash(get(Forum, key))
        update(Forum, key, 'SET forum_name = :val', {':val' => forum_name}) if forum.forum_name != forum_name
        update(Forum, key, 'SET description = :val', {':val' => description}) if forum.description != description
        original_moderators = forum.moderators.map { |group| group['id'] }
        to_add = forum_params['moderator_ids'] - original_moderators
        to_remove = original_moderators - forum_params['moderator_ids']
        to_add.each do |group|
          ModeratorGroup.create(group: group, forum: forum.id)
        end
        to_remove.each do |group|
          delete(ModeratorGroup, {forum: forum.id, group: group})
        end
        update_successful
      end
    rescue Exception => e
      Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
      if params[:forum_id].blank?
        create_failed error_msg || t("forem.admin.forum.not_created")
      else
        update_failed error_msg || t("forem.admin.category.not_updated")
      end
    end

    def edit
      get_forum_from_params params['category'], :id
    end

    def destroy
      delete_forum(params[:category], params[:id])
      destroy_successful
    end

    private

    def forum_params
      params.require(:forum).permit(:category_id, :title, :description, :position, {:moderator_ids => []})
    end

    def create_successful
      flash[:notice] = t("forem.admin.forum.created")
      redirect_to admin_forums_path
    end

    def create_failed(alert_msg)
      flash.now.alert = alert_msg
      for_new_forum
      render action: 'new'
    end

    def destroy_successful
      flash[:notice] = t("forem.admin.forum.deleted")
      redirect_to admin_forums_path
    end

    def update_successful
      flash[:notice] = t("forem.admin.forum.updated")
      redirect_to admin_forums_path
    end

    def update_failed(alert_msg)
      flash.now.alert = alert_msg
      get_forum_from_params params['forum']['category'], :forum_id
      render action: 'edit'
    end

    def for_new_forum
      @categories = attributes(Category.all)
      @forum = Forum.new
      @groups = attributes(Group.all)
    end

    def get_forum_from_params(category, id_key)
      for_new_forum
      @category = get(Category, {id: category})
      forum = get(Forum, {category: category, id: params[id_key]})
      @forum = Forum.new_from_hash(forum)
      @forum_moderators = @forum.moderators.map { |m| m['id'] }
    end

  end
end
