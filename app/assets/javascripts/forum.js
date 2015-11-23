(function () {

    var forumController = function ($scope, $log, $location, $compile, $uibModal, $filter, ForumService) {
        $scope.oneAtATime = true;

        $scope.forumStatus = {
            isFirstOpen: true,
            isFirstDisabled: false
        };
        $scope.topicStatus = {
            isFirstOpen: true,
            isFirstDisabled: false
        };
        $scope.postStatus = {
            isFirstOpen: true,
            isFirstDisabled: false
        };

        var onError = function (reason) {
            $log.error('onError', reason);
        };

        var renderCategoriesTable = function (data) {
            var categories = data.categories;
            $scope.favoriteForums = data.favoriteForums;
            $log.info('categories', categories);
            $log.info('favoriteForums', $scope.favoriteForums);
            var template = _.template(htmlTemplates.forums);
            var columns = [
                {
                    'sTitle': 'Category',
                    'sClass': 'center panel-title title-column',
                },
                {
                    'sTitle': 'Forums',
                    'sClass': 'center panel-title content-column',
                    'render': function (data, type, row) {
                        return template({data: data});
                    }
                },
            ]

            var aaData = _.map(categories, function (c) {
                return [c.category_name, c];
            });

            var tableDefinition = {
                bDestroy: true,
                aaData: aaData,
                aoColumns: columns,
                columnDefs: [
                    {orderable: false, targets: 1},
                ],
                bLengthChange: false,
                bInfo: false,
                dom: '<"categories-table-toolbar">frtip',
                pagingType: 'full_numbers',
                fnDrawCallback: function (oSettings) {
                    $compile($('div#categoriesTableDiv'))($scope);
                },
            };
            $log.info('Categories table definition', tableDefinition);
            $('table#categoriesTable').dataTable(tableDefinition);
            var refreshButtonHtml = '<button class="btn btn-info" type="button" ng-click="refreshCategoriesTable()"><i class="glyphicon glyphicon-refresh"></i>&nbsp;Refresh</button>';
            var tableToolBar = 'div.categories-table-toolbar';
            $(tableToolBar).html(refreshButtonHtml);
            $compile(angular.element(tableToolBar).contents())($scope);
        };

        var renderTopicsTable = function (data) {
            var topics = data.topics;
            $scope.favoriteTopics = data.favoriteTopics;
            $log.info('topics', topics);
            $log.info('favoriteTopics', $scope.favoriteTopics);
            var template = _.template(htmlTemplates.topic);
            var columns = [
                {
                    'sTitle': 'last_post_at',
                },
                {
                    'sTitle': '', // picture
                    'sWidth': '20px',
                    'render': function (data, type, row) {
                        return '<img src="' + data + '" alt="Avatar">';
                    }
                },
                {
                    'sTitle': 'Subject',
                    'sClass': 'panel-title title-column',
                    'render': function (data, type, row) {
                        if ($scope.userId == data.user.id) {
                            data.edit = true;
                        }
                        return template({data: data});
                    }
                },
                {
                    'sTitle': 'Views',
                    'sClass': 'center panel-title content-column',
                    'sWidth': '18px',
                },
                {
                    'sTitle': 'Replies',
                    'sClass': 'center panel-title content-column',
                    'sWidth': '18px',
                },
            ]

            var aaData = _.map(topics, function (t) {
                t.created_at_ago = jQuery.timeago(new Date(t.created_at * 1000));
                t.last_post_at_ago = jQuery.timeago(new Date(t.last_post_at * 1000));
                return [t.last_post_at, t.last_post_by.picture, t, t.views_count, t.posts_count];
            });

            var tableDefinition = {
                bDestroy: true,
                aaData: aaData,
                aoColumns: columns,
                columnDefs: [
                    {orderable: false, targets: [1, 2]},
                    {visible: false, targets: [0]},
                    {searchable: false, targets: [0, 1, 3, 4]},
                ],
                aaSorting: [[0, 'desc']],
                bLengthChange: false,
                bInfo: false,
                dom: '<"topics-table-toolbar">frtip',
                pagingType: 'full_numbers',
                fnDrawCallback: function (oSettings) {
                    $compile(angular.element('div#topicsTableDiv').contents())($scope);
                },
            };
            $log.info('Topics table definition', tableDefinition);
            $('table#topicsTable').dataTable(tableDefinition);
            var refreshButtonHtml = '<button ng-click="openModal(\'New Topic\', \'\', \'\', \'\', $event)" class="btn btn-danger" type="button" ng-hide="userId == -1"><i class="glyphicon glyphicon-pencil"></i>&nbsp;New Topic</button>' +
                '<button class="btn btn-info" type="button" ng-click="refreshTopicsTable()"><i class="glyphicon glyphicon-refresh"></i>&nbsp;Refresh</button>';
            var tableToolBar = 'div.topics-table-toolbar';
            $(tableToolBar).html(refreshButtonHtml);
            $compile(angular.element(tableToolBar).contents())($scope);
        };

        var renderPostsTable = function (data) {
            $log.info('posts', data);
            var userInfoTemplate = _.template(htmlTemplates.userInfo);
            var postBodyTemplate = _.template(htmlTemplates.postBody);
            var columns = [
                {
                    'sTitle': 'updated_at',
                },
                {
                    'sTitle': '', // picture
                    'sWidth': '20px',
                    'render': function (data, type, row) {
                        return userInfoTemplate({data: data});
                    }
                },
                {
                    'sTitle': 'Text',
                    'sClass': 'panel-title title-column',
                    'render': function (data, type, row) {
                        return postBodyTemplate({data: data});
                    }
                },
            ]

            var postsMap = _.object(_.map(data, function (item) {
                return [item.id, item];
            }));
            var aaData = _.map(data, function (p) {
                p.updated_at_time = $filter('date')(p.updated_at * 1000, 'MMM d, y h:mm a');
                if ($scope.userId == p.user.id) {
                    p.edit = true;
                }
                p.reply_to_post = postsMap[p.reply_to_post];
                return [p.updated_at, p.user, p];
            });

            $log.info('renderPostsTable aaData', aaData);
            var tableDefinition = {
                bDestroy: true,
                aaData: aaData,
                aoColumns: columns,
                columnDefs: [
                    {visible: false, targets: [0]},
                    {searchable: false, targets: [0, 1]},
                ],
                aaSorting: [[0, 'asc']],
                bLengthChange: false,
                bInfo: false,
                dom: '<"posts-table-toolbar">frtip',
                pagingType: 'full_numbers',
                fnDrawCallback: function (oSettings) {
                    $compile(angular.element('div#postsTableDiv').contents())($scope);
                },
            };
            $log.info('Posts table definition', tableDefinition);
            $('table#postsTable').dataTable(tableDefinition);
            var refreshButtonHtml = '<button ng-click="openModal(\'New Post\', \'' + ($scope.selectedTopic == undefined ? '' : $scope.selectedTopic.id) +
                '\', \'\', \'' + ($scope.selectedTopic == undefined ? '' : $scope.selectedTopic.subject) +
                '\', $event)" class="btn btn-danger" type="button" ng-hide="userId == -1"><i class="glyphicon glyphicon-pencil"></i>&nbsp;New Post</button>' +
                '<button class="btn btn-info" type="button" ng-click="refreshPostsTable()"><i class="glyphicon glyphicon-refresh"></i>&nbsp;Refresh</button>';
            var tableToolBar = 'div.posts-table-toolbar';
            $(tableToolBar).html(refreshButtonHtml);
            $compile(angular.element(tableToolBar).contents())($scope);
            $('div#postsTable_paginate a#postsTable_last').trigger('click');
        };

        $scope.init = function () {
            $scope.userId = parseInt($('span#userId').text());
            $log.info('userId', $scope.userId);
            var params = $location.search();
            var c = params.c;
            var f = params.f;
            var t = params.t;
            var p = params.p;
            if (t) {
                ForumService.getForum(c, f).then(function (data) {
                    $scope.selectedForum = data;
                    $scope.selectTopic(f, t);
                }, onError);
            } else if (f) {
                $scope.selectForum(f, c);
            } else {
                $scope.forumStatus.open = true;
            }
        };
        $scope.toggleFavoriteForum = function (name, id, category, $event) {
            $log.info('toggleFavoriteForum: name ' + name + ', id ' + id + ', category ' + category);
            var target = $($event.target);
            if (target.hasClass('glyphicon-star-empty')) {
                $log.info('add to favoriteForums', $scope.favoriteForums.length);
                $scope.favoriteForums.push({
                    name: name,
                    id: id,
                    category: category,
                });
                $log.info('favoriteForums', $scope.favoriteForums.length);
                $log.info('POST /favorites: forum = ' + id);
                ForumService.addUserFavorite({type: 'forum', category: category, forum: id});
            }

            if (target.hasClass('glyphicon-star')) {
                $log.info('remove from favoriteForums', $scope.favoriteForums.length);
                $scope.favoriteForums = _.without($scope.favoriteForums,
                    _.findWhere($scope.favoriteForums, {id: id}));
                $log.info('favoriteForums', $scope.favoriteForums.length);
                $log.info('DELETE /favorites: forum = ' + id);
                ForumService.removeUserFavorite(id, {type: 'forum'});
            }
            target.toggleClass('glyphicon-star-empty glyphicon-star');
        };
        $scope.toggleFavoriteTopic = function (forum, id, subject, $event) {
            $log.info('toggleFavoriteTopic: forum ' + forum + ', id ' + id + ', subject' + subject);
            var target = $($event.target);
            if (target.hasClass('glyphicon-star-empty')) {
                $log.info('add to favoriteTopics', $scope.favoriteTopics.length);
                $scope.favoriteTopics.push({
                    id: id,
                    forum: forum,
                    subject: subject,
                });
                $log.info('favoriteTopics', $scope.favoriteTopics.length);
                $log.info('POST /favorites: topic = ' + id);
                ForumService.addUserFavorite({type: 'topic', topic: id, forum: forum});
            }

            if (target.hasClass('glyphicon-star')) {
                $log.info('remove from favoriteTopics', $scope.favoriteTopics.length);
                $scope.favoriteTopics = _.without($scope.favoriteTopics,
                    _.findWhere($scope.favoriteTopics, {id: id}));
                $log.info('favoriteTopics', $scope.favoriteTopics.length);
                $log.info('DELETE /favorites: topic = ' + id);
                ForumService.removeUserFavorite(id, {type: 'topic'});
            }
            target.toggleClass('glyphicon-star-empty glyphicon-star');
        };
        $scope.selectForum = function (id, category, $event) {
            $log.info('selectForum: forum ' + id + ', category ' + category);
            $location.search('c', category);
            $location.search('f', id);
            $location.search('t', null);
            $location.search('p', null);
            if ($event) {
                var oTable = $('table#categoriesTable').dataTable();
                oTable.$('span.selected-forum').removeClass('selected-forum');
                $('div#categories-table-banner span.selected-forum').removeClass('selected-forum');
                var target = $($event.target);
                target.addClass('selected-forum');
            }
            $scope.topicStatus.open = true;
            ForumService.getForum(category, id).then(function (data) {
                $scope.selectedForum = data;
                var found = _.findWhere($scope.favoriteForums, {id: id});
                $log.debug('found', found);
                $scope.selectedForum.favorite = found != undefined;
                $log.info('selectedForum', $scope.selectedForum);
                ForumService.getTopicsWithFavorites(id).then(renderTopicsTable, onError);
            }, onError);
        };
        $scope.selectTopic = function (forum, id, $event) {
            $log.info('selectTopic: forum ' + forum + ', id ' + id);
            $location.search('t', id);
            $location.search('p', null);
            if ($event) {
                var oTable = $('table#topicsTable').dataTable();
                oTable.$('span.selected-topic').removeClass('selected-topic');
                $('div#topics-table-banner span.selected-topic').removeClass('selected-topic');
                var target = $($event.target);
                target.addClass('selected-topic');
            }
            $scope.postStatus.open = true;
            ForumService.getTopic(forum, id).then(function (data) {
                $scope.selectedTopic = data;
                $log.info('favoriteTopics', $scope.favoriteTopics);
                var found = _.findWhere($scope.favoriteTopics, {id: id});
                $log.debug('found', found);
                $scope.selectedTopic.favorite = found != undefined;
                $log.info('selectedTopic', $scope.selectedTopic);
                ForumService.getPosts(id).then(renderPostsTable, onError);
            }, onError);
        };
        $scope.deleteTopic = function (forum, id) {
            if (!confirm("Are you sure?")) {
                $log.info('Cancel deletion of topic ' + id);
                return;
            }

            $log.info('Deleting topic ' + id);
            $scope.favoriteTopics = _.without($scope.favoriteTopics,
                _.findWhere($scope.favoriteTopics, {id: id}));
            ForumService.deleteTopic(forum, id);
            $scope.refreshTopicsTable();
        };
        $scope.deletePost = function (topic, id) {
            if (!confirm("Are you sure?")) {
                $log.info('Cancel deletion of post ' + id);
                return;
            }

            $log.info('Deleting post ' + id);
            ForumService.deletePost(topic, id);
            $scope.refreshPostsTable();
        };
        $scope.replyToPost = function (topic, id, $event) {
            $log.info('replyToPost: topic ' + topic + ', id ' + id);
            if ($scope.userId == -1) {
                location.href = '/users/sign_in';
            }
            $scope.replyToPostId = id;
            $scope.openModal('New Post', topic, id, $scope.selectedTopic.subject, $event);
        };
        $scope.refreshCategoriesTable = function () {
            ForumService.getCategoriesWithFavorites().then(renderCategoriesTable, onError);
        };
        $scope.refreshTopicsTable = function () {
            ForumService.getTopicsWithFavorites($scope.selectedForum.id).then(renderTopicsTable, onError);
        };
        $scope.refreshPostsTable = function () {
            ForumService.getPosts($scope.selectedTopic.id).then(renderPostsTable, onError);
        };
        $scope.$watch('forumStatus.open', function (newValue, oldValue) {
            $log.info('forumStatus.open', $scope.forumStatus.open);
            if ($scope.forumStatus.open) {
                $scope.refreshCategoriesTable();
            }
        });
        $scope.$watch('topicStatus.open', function (newValue, oldValue) {
            $log.info('topicStatus.open', $scope.topicStatus.open);
            if ($scope.topicStatus.open) {
                $scope.refreshTopicsTable();
            }
        });

        $scope.openModal = function (modalTitle, topicId, postId, subject, $event) {
            $log.info('openModal modalTitle: ' + modalTitle + ', topicId: ' +
                topicId + ', postId: ' + postId + ', subject: ' + subject);
            var modalInstance = $uibModal.open({
                animation: false,
                templateUrl: 'modalContent.html',
                controller: 'ForumModalInstanceController',
                size: 'lg',
                resolve: {
                    forum: function () {
                        return $scope.selectedForum;
                    },
                    title: function () {
                        return modalTitle;
                    },
                    topicId: function () {
                        return topicId;
                    },
                    postId: function () {
                        return postId;
                    },
                    subject: function () {
                        return subject;
                    },
                    text: function () {
                        var text = '';
                        if (modalTitle == 'Edit Post') {
                            text = $($event.target).parent().parent().parent().children('div.messageInfo')[0].innerHTML;
                            $log.info('text', text);
                        }
                        return text;
                    },
                    replyToPostId: function () {
                        return $scope.replyToPostId;
                    },
                }
            });

            modalInstance.rendered.then(function () {
                if (modalTitle != 'Edit Topic') {
                    //var editor = CKEDITOR.instances['ckeditor'];
                    //if (editor) {
                    //    editor.destroy(true);
                    //}
                    CKEDITOR.replace('ckeditor');
                }
            });

            modalInstance.result.then(function () {
                $scope.replyToPostId = null;
                $log.info('Modal ok');
                switch (modalTitle) {
                    case 'New Topic':
                    case 'Edit Topic':
                        $scope.refreshTopicsTable();
                        break;
                    case 'New Post':
                    case 'Edit Post':
                        $scope.refreshPostsTable();
                        break;
                    default:
                        $log.error('Invalid modalTitle: ' + modalTitle);
                }
            }, function () {
                $scope.replyToPostId = null;
                $log.info('Modal dismissed at: ' + new Date());
            });
        };
    };

    forum.controller('ForumController', ['$scope', '$log', '$location', '$compile', '$uibModal', '$filter', 'ForumService', forumController]);
}());