window.htmlTemplates = {}
window.htmlTemplates.forums = '''
  <% _.each( data.forums, function( f ){ %>
    <div style="float:left">
      <i class="star glyphicon glyphicon-star<%= f.favorite ? '' : '-empty' %> forum-icon" ng-click="toggleFavoriteForum('<%= f.forum_name %>', '<%= f.id %>', '<%= data.id %>', $event)"></i>
      <span class="forum-item" ng-click="selectForum('<%= f.forum_name %>', '<%= f.id %>', '<%= data.id %>', $event)"><%= f.forum_name %></span>
    </div>
  <% }); %>
'''
window.htmlTemplates.topic = '''
  <div class="td-title">
    <%= data.subject %>
  </div>
  <div class="td-second-row">
    <%= data.user.name %>, <%= data.created_at_ago %>&nbsp; &nbsp; &nbsp;Latest reply: <%= data.last_post_by.name %>, <%= data.last_post_at_ago %>
  </div>
'''