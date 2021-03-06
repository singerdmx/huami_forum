module ForumsHelper
  include Connection
  include TopicsHelper

  def simple_forum_hash(forum_hash)
    h = {}
    %w(id forum_name description category category_name last_post_id last_topic_id).each do |k|
      h[k] = forum_hash[k]
    end

    %w(updated_at views_count topics_count posts_count created_at last_post_by).each do |k|
      h[k] = forum_hash[k].to_i
    end

    h
  end

  def find_forum(category_id = params[:category_id], forum_id = params[:id])
    fail 'category_id is not defined!' unless category_id
    fail 'id is not defined!' unless forum_id
    @forum = get(Forum, {category: category_id, id: forum_id})
    fail "Unable to find forum given category #{category_id} forum_id #{forum_id}" unless @forum
  end

  def find_forum_by_name(category_id, name)
    fail 'category_id is not defined!' unless category_id
    fail 'name is not defined!' unless name
    query(Forum, 'category = :category_id and forum_name = :n',
          {':category_id' => category_id, ':n' => name}, 'name_index')
  end

  def create_forum(category, forum_name, description, moderator_groups)
    created_forum = Forum.create(category: category, category_name: get(Category, {id: category})['category_name'],
                                 forum_name: forum_name, description: description)
    Rails.logger.info "created_forum #{created_forum.inspect}"

    (moderator_groups || []).each do |group_id|
      created_moderator_group = ModeratorGroup.create(group: group_id, forum: created_forum.attributes['id'])
      Rails.logger.info "created_moderator_group #{created_moderator_group.inspect}"
    end
  end

  def delete_forum(category, forum_id)
    delete(Forum, {category: category, id: forum_id})
    groups = query(ModeratorGroup, 'forum = :f', ':f' => forum_id)
    groups.each do |group|
      g = simple_group_hash(group)
      delete(ModeratorGroup, {group: g['id'], forum: forum_id})
    end
    topics = query(Topic, 'forum = :f', {':f' => forum_id})
    topics.each do |topic|
      delete_topic(topic['forum'], topic['id'])
    end
    #TODO delete associated user favorites or have a to_delete table to have a cron job periodically scan user favorites
  end

  def topics_count(forum)
    if forem_admin_or_moderator?(forum)
      forum.topics.count
    else
      forum.topics.approved.count
    end
  end

  def posts_count(forum)
    if forem_admin_or_moderator?(forum)
      forum.posts.count
    else
      forum.posts.approved.count
    end
  end
end
