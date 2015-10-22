module ForumsHelper
  include Connection

  def simple_hash(forum_hash)
    h = {}
    %w(id name).each do |k|
      h[k] = forum_hash[k]
    end

    h
  end

  def find_forum(category_id = params[:category_id], forum_id = params[:id])
    fail 'category_id is not defined!' unless category_id
    fail 'id is not defined!' unless forum_id
    @forum = get(Forum, {category: category_id, id: forum_id})
    fail "Unable to find forum given category #{category_id} forum_id #{forum_id}" unless @forum
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
