require 'securerandom'

###############################
#           User              #
###############################
User.delete_all
Profile.delete_all

user_size = 5
users = user_size.times.map do |i|
  User.create!(
      email: "user#{i}@test.com",
      password: 'user1234',
      password_confirmation: 'user1234',
      name: 'u' + i.to_s,
      confirmed_at: Time.now,
      confirmation_sent_at: Time.now - 30,
      forem_admin: i == 0)
end

users << User.create!(
    email: 'singerdmx@gmail.com',
    password: '12345678',
    password_confirmation: '12345678',
    name: 'Xin Yao',
    confirmed_at: Time.now,
    confirmation_sent_at: Time.now - 30,
    forem_admin: true)

users.each do |u|
  Profile.create!(user_id: u.id)
end

user = User.first

###############################
#         DynamoDB            #
###############################

require_relative '../app/dynamo_db/cleaner'
require_relative '../app/dynamo_db/initializer'

cleaner = DynamoDatabase::Cleaner.new
cleaner.clean

DynamoDatabase::Initializer.load_table_classes

read_capacity_units = 10
write_capacity_units = 5

client = Aws::DynamoDB::Client.new

###############################
#         Category            #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
    ],
    table_name: Category.get_table_name,
    key_schema: [
        {
            attribute_name: 'id',
            key_type: 'HASH',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

categories = []
categories << Category.create!(category_name: 'Announcements')
categories << Category.create!(category_name: 'General Support')
categories << Category.create!(category_name: 'Accessories')
categories << Category.create!(category_name: 'Development')

###############################
#           Forum             #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'category',
            attribute_type: 'S',
        },
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
        {
            attribute_name: 'forum_name',
            attribute_type: 'S',
        },
    ],
    table_name: Forum.get_table_name,
    key_schema: [
        {
            attribute_name: 'category',
            key_type: 'HASH',
        },
        {
            attribute_name: 'id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
    local_secondary_indexes: [
        {
            index_name: 'name_index',
            key_schema: [
                {
                    attribute_name: 'category',
                    key_type: 'HASH',
                },
                {
                    attribute_name: 'forum_name',
                    key_type: 'RANGE',
                },
            ],
            projection: {
                projection_type: 'INCLUDE',
                non_key_attributes: ['id'],
            },
        },
    ],
)

forums = []
forums << Forum.create!(category: categories.first.id,
                       category_name: categories.first.category_name,
                       forum_name: "Announcements Forum",
                       description: "Mi Band updates")

forums << Forum.create!(category: categories.first.id,
                       category_name: categories.first.category_name,
                       forum_name: "App Forum",
                       description: "App discussion")

forums << Forum.create!(category: categories[1].id,
                       category_name: categories[1].category_name,
                       forum_name: "Beginner Forum",
                       description: "Beginner tutorial")

forums << Forum.create!(category: categories[2].id,
                       category_name: categories[2].category_name,
                       forum_name: "Battery",
                       description: "Battery discussion")

forums << Forum.create!(category: categories[2].id,
                       category_name: categories[2].category_name,
                       forum_name: "Bands",
                       description: "Band styles")

forums << Forum.create!(category: categories[3].id,
                       category_name: categories[3].category_name,
                       forum_name: "Contribute to App",
                       description: "How to contribute your code")

if ENV['massive_seeding']
  (0..2).each do |i|
    c = Category.create!(category_name: 'Category - ' + i.to_s)
    categories << c
    (0..3).each do |j|
      forums << Forum.create!(category: c.id,
                             category_name: c.category_name,
                             forum_name: "Forum - #{i}#{j}",
                             description: "f#{i}#{j}")
    end
  end
end

###############################
#        User  Topics         #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'updated_at',
            attribute_type: 'N',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: UserTopic.get_table_name,
    key_schema: [
        {
            attribute_name: 'user_id',
            key_type: 'HASH',
        },
        {
            attribute_name: 'updated_at',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

###############################
#           Topic             #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'forum',
            attribute_type: 'S',
        },
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
        {
            attribute_name: 'last_post_at',
            attribute_type: 'N',
        },
    ],
    table_name: Topic.get_table_name,
    key_schema: [
        {
            attribute_name: 'forum',
            key_type: 'HASH',
        },
        {
            attribute_name: 'id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
    local_secondary_indexes: [
        {
            index_name: 'last_post_at_index',
            key_schema: [
                {
                    attribute_name: 'forum',
                    key_type: 'HASH',
                },
                {
                    attribute_name: 'last_post_at',
                    key_type: 'RANGE',
                },
            ],
            projection: {
                projection_type: 'ALL',
            },
        },
    ],
)

topics = []
topics << Topic.create!(
    forum: forums.first.id,
    category: forums.first.category,
    last_post_at: Time.now.to_i - 10,
    last_post_by: user.id,
    subject: 'How to upgrade',
    user_id: user.id,
    state: 'approved')

sleep 0.1

topics << Topic.create!(
    forum: forums.first.id,
    category: forums.first.category,
    last_post_at: Time.now.to_i,
    last_post_by: user.id,
    subject: 'Amazfit new function',
    user_id: user.id,
    state: 'approved')

if ENV['massive_seeding']
  forums.each do |f|
    (0..90).each do |i|
      topics << Topic.create!(
          forum: f.id,
          category: f.category,
          last_post_at: Time.now.to_i - i * 10,
          last_post_by: users[i % users.size].id,
          subject: "Topic #{i}",
          user_id: users[SecureRandom.random_number(100) % users.size].id,
          state: 'approved')
    end
  end
end

###############################
#           Post              #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
        {
            attribute_name: 'topic',
            attribute_type: 'S',
        },
        {
            attribute_name: 'updated_at',
            attribute_type: 'N',
        },
    ],
    table_name: Post.get_table_name,
    key_schema: [
        {
            attribute_name: 'topic',
            key_type: 'HASH',
        },
        {
            attribute_name: 'id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
    local_secondary_indexes: [
        {
            index_name: 'updated_at_index',
            key_schema: [
                {
                    attribute_name: 'topic',
                    key_type: 'HASH',
                },
                {
                    attribute_name: 'updated_at',
                    key_type: 'RANGE',
                },
            ],
            projection: {
                projection_type: 'ALL',
            },
        },
    ],
)

posts = []
posts << Post.create!(
    category: topics.first.category,
    forum: topics.first.forum,
    topic: topics.first.id,
    body_text: 'My own experience',
    state: 'approved',
    user_id: user.id)

if ENV['massive_seeding']
  1000.times do
    topic = topics[SecureRandom.random_number(20)]
    posts << Post.create!(
        category: topic.category,
        forum: topic.forum,
        topic: topic.id,
        body_text: "Post of topic #{topic}",
        state: 'approved',
        user_id: users[SecureRandom.random_number(100) % users.size].id)
  end
end

posts << Post.create!(
    category: topics.first.category,
    forum: topics.first.forum,
    topic: topics.first.id,
    body_text: 'It does not work',
    state: 'approved',
    user_id: user.id)

###############################
#           Views             #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: View.get_table_name,
    key_schema: [
        {
            attribute_name: 'user_id',
            key_type: 'HASH',
        },
        {
            attribute_name: 'id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

views = []
views << View.create!(
    user_id: user.id,
    id: "#{Topic.get_table_name}##{topics.first.id}",
    viewable_id: topics.first.id,
    viewable_type: Topic.get_table_name)

###############################
#           Group             #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'id',
            attribute_type: 'S',
        },
    ],
    table_name: Group.get_table_name,
    key_schema: [
        {
            attribute_name: 'id',
            key_type: 'HASH',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

groups = []
groups << Group.create!(name: 'Moderator')
groups << Group.create!(name: 'Normal User')
groups << Group.create!(name: 'Admin')

###############################
#         Membership          #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'group_id',
            attribute_type: 'S',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: Membership.get_table_name,
    key_schema: [
        {
            attribute_name: 'group_id',
            key_type: 'HASH',
        },
        {
            attribute_name: 'user_id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

memberships = []
memberships << Membership.create!(group_id: groups.first.id,
                                 user_id: user.id)

memberships << Membership.create!(group_id: groups[1].id,
                                 user_id: users[1].id)

memberships << Membership.create!(group_id: groups[2].id,
                                 user_id: user.id)
memberships << Membership.create!(group_id: groups[2].id,
                                 user_id: users[2].id)

###############################
#       ModeratorGroup        #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'group',
            attribute_type: 'S',
        },
        {
            attribute_name: 'forum',
            attribute_type: 'S',
        },
    ],
    table_name: ModeratorGroup.get_table_name,
    key_schema: [
        {
            attribute_name: 'forum',
            key_type: 'HASH',
        },
        {
            attribute_name: 'group',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

moderator_groups = []
forums.each do |forum|
  moderator_groups << ModeratorGroup.create!(group: groups.first.id,
                                            forum: forum.id)
  moderator_groups << ModeratorGroup.create!(group: groups.last.id,
                                            forum: forum.id)
end

###############################
#         Subscription        #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'topic',
            attribute_type: 'S',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: Subscription.get_table_name,
    key_schema: [
        {
            attribute_name: 'topic',
            key_type: 'HASH',
        },
        {
            attribute_name: 'user_id',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

subscriptions = []
users.each do |u|
  subscriptions << Subscription.create!(topic: topics.first.id,
                                       user_id: u.id)
end

###############################
#       Favorite Forums       #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'forum',
            attribute_type: 'S',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: FavoriteForum.get_table_name,
    key_schema: [
        {
            attribute_name: 'user_id',
            key_type: 'HASH',
        },
        {
            attribute_name: 'forum',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

(0..3).each do |i|
  FavoriteForum.create!(user_id: user.id, forum: forums[i].id, category: forums[i].category)
end

###############################
#       Favorite Topics       #
###############################

client.create_table(
    attribute_definitions: [
        {
            attribute_name: 'topic',
            attribute_type: 'S',
        },
        {
            attribute_name: 'user_id',
            attribute_type: 'N',
        },
    ],
    table_name: FavoriteTopic.get_table_name,
    key_schema: [
        {
            attribute_name: 'user_id',
            key_type: 'HASH',
        },
        {
            attribute_name: 'topic',
            key_type: 'RANGE',
        },
    ],
    provisioned_throughput: {
        read_capacity_units: read_capacity_units,
        write_capacity_units: write_capacity_units,
    },
)

(0..[topics.size - 1, 16].min).each do |i|
  FavoriteTopic.create!(user_id: user.id, topic: topics[i].id, forum: topics[i].forum)
end

