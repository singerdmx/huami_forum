(function () {
    // Please note that $modalInstance represents a modal window (instance) dependency.
    // It is not the same as the $uibModal service used below.
    var forumModalInstanceController = function ($scope, $log, $modalInstance,
                                                 ForumService, forum, title, topicId, postId, subject, text, replyToPostId) {
        $scope.modalTitle = title;
        $scope.modalTopicId = topicId;
        $scope.modalPostId = postId;
        $scope.modalSubject = subject;
        $scope.modalText = text;
        $scope.modalSubjectDisabled = false;
        if (title == 'New Post' || title == 'Edit Post') {
            $scope.modalSubjectDisabled = true;
        }

        $scope.submitForm = function (subject) {
            $log.info('modalSubject', subject);
            if (CKEDITOR.instances['ckeditor']) {
                var text = CKEDITOR.instances['ckeditor'].getData();
                $log.info('ckeditor data', text);
            }
            switch (title) {
                case 'New Topic':
                    ForumService.newTopic(forum.category, forum.id, subject, text);
                    break;
                case 'Edit Topic':
                    ForumService.editTopic(forum.id, topicId, subject);
                    break;
                case 'New Post':
                    ForumService.newPost(forum.category, forum.id, topicId, text, replyToPostId);
                    break;
                case 'Edit Post':
                    ForumService.editPost(topicId, postId, text);
                    break;
                default:
                    $log.error('Invalid title: ' + title);
            }
            $modalInstance.close();
        };

        $scope.cancelForm = function () {
            $modalInstance.dismiss('cancel');
        };
    };

    forum.controller('ForumModalInstanceController',
        ['$scope', '$log', '$modalInstance', 'ForumService',
            'forum', 'title', 'topicId', 'postId', 'subject', 'text', 'replyToPostId', forumModalInstanceController]);

}());