require_relative '../../app/dynamo_db/connection'

class Topic < OceanDynamo::Table
  include Connection

  dynamo_schema(timestamps: [:created_at, :updated_at]) do
    attribute :forum
    attribute :subject
    attribute :user, :integer
    attribute :state, default: 'approved'
    attribute :locked, :boolean, default: false
    attribute :pinned, :boolean, default: false
    attribute :hidden, :boolean, default: false
    attribute :last_post_at, :integer
    attribute :views_count, :integer, default: 0
  end

  include Concerns::Viewable
  include Workflow
  include StateWorkflow

  attr_accessor :moderation_option

  validates :subject, :presence => true, :length => {maximum: 255}
  validates :user, :forum, :presence => true

  # after_create :subscribe_poster
  # after_create :skip_pending_review, :unless => :moderated?

  class << self
    def visible
      where(:hidden => false)
    end

    def by_pinned
      order('forem_topics.pinned DESC').
          order('forem_topics.id')
    end

    def by_most_recent_post
      order('forem_topics.last_post_at DESC').
          order('forem_topics.id')
    end

    def by_pinned_or_most_recent_post
      order('forem_topics.pinned DESC').
          order('forem_topics.last_post_at DESC').
          order('forem_topics.id')
    end

    def pending_review
      where(:state => 'pending_review')
    end

    def approved
      where(:state => 'approved')
    end

    def approved_or_pending_review_for(user)
      if user
        where("forem_topics.state = ? OR " +
                  "(forem_topics.state = ? AND forem_topics.user_id = ?)",
              'approved', 'pending_review', user.id)
      else
        approved
      end
    end
  end

  def to_s
    subject
  end

  # Cannot use method name lock! because it's reserved by AR::Base
  def lock_topic!
    update_column(:locked, true)
  end

  def unlock_topic!
    update_column(:locked, false)
  end

  # Provide convenience methods for pinning, unpinning a topic
  def pin!
    update_column(:pinned, true)
  end

  def unpin!
    update_column(:pinned, false)
  end

  def moderate!(option)
    send("#{option}!")
  end

  # A Topic cannot be replied to if it's locked.
  def can_be_replied_to?
    !locked?
  end

  def subscribe_poster
    subscribe_user(user_id)
  end

  def subscribe_user(subscriber_id)
    if subscriber_id && !subscriber?(subscriber_id)
      Subscription.create!(topic_id: guid, subscriber_id: subscriber_id)
    end
  end

  def unsubscribe_user(subscriber_id)
    subscriptions_for(subscriber_id).destroy_all
  end

  def subscriber?(subscriber_id)
    subscriptions_for(subscriber_id).any?
  end

  def subscription_for(subscriber_id)
    subscriptions_for(subscriber_id).first
  end

  def subscriptions_for(subscriber_id)
    [] # Subscription.where(:subscriber_id => subscriber_id)
  end

  def last_page
    (self.posts.count.to_f / Forem.per_page.to_f).ceil
  end

  protected

  def skip_pending_review
    update_column(:state, 'approved')
  end

  def approve
    first_post = posts.by_created_at.first
    first_post.approve! unless first_post.approved?
  end

  def moderated?
    user.forem_moderate_posts?
  end
end
