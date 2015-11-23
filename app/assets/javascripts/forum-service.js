(function () {
    var forumService = function ($http, $log, $q) {

        var onError = function (response) {
            $log.error('error response', response);
            var data = response.data;
            if (response.status === 401) {
                if (confirm(data.message || data.error + '\nGo to sign in page?')) {
                    location.href = '/users/sign_in';
                }
            }
        };

        var addUserFavorite = function (params) {
            return $http.post('/favorites.json', params)
                .then(function (response) {
                    $log.info('POST /favorites response', response);
                    return response.data;
                }, onError);
        };

        var removeUserFavorite = function (favorite, params) {
            return $http.delete('/favorites/' + favorite + '.json', {params: params})
                .then(function (response) {
                    $log.info('DELETE /favorites response', response);
                    return response.data;
                }, onError);
        };

        var getCategoriesWithFavorites = function () {
            $log.info('getCategoriesWithFavorites');
            return $q.all([$http.get('/categories.json'), $http.get('/favorites?type=forum')]).then(function (response) {
                var categories = response[0].data;
                $log.info('categories', categories);
                var userFavorites = response[1].data;
                $log.info('userFavorites', userFavorites);
                var favoriteForums = [];

                _.each(categories, function (c) {
                    _.each(c.forums, function (f) {
                        if (_.contains(userFavorites, f.id)) {
                            f.favorite = true;
                            favoriteForums.push({
                                id: f.id,
                                name: f.forum_name,
                                category: c.id,
                            });
                        }
                    });
                });
                return {
                    categories: categories,
                    favoriteForums: favoriteForums,
                };
            }, onError);
        };

        var getForum = function (category, forum_id) {
            var url = '/categories/' + category + '/forums/' + forum_id + '.json';
            return $http.get(url)
                .then(function (response) {
                    $log.info('GET ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var getTopicsWithFavorites = function (forum_id) {
            $log.info('getTopicsWithFavorites');
            return $q.all([$http.get('/forums/' + forum_id + '/topics.json'), $http.get('/favorites.json?type=topic')]).then(function (response) {
                var topics = response[0].data;
                $log.info('topics', topics);
                var userFavorites = response[1].data;
                $log.info('userFavorites', userFavorites);
                var favoriteTopics = [];

                _.each(topics, function (t) {
                    if (_.contains(userFavorites, t.id)) {
                        t.favorite = true;
                        favoriteTopics.push(t);
                    }
                });
                return {
                    topics: topics,
                    favoriteTopics: favoriteTopics,
                };
            }, onError);
        };

        var getTopic = function (forum_id, topic_id) {
            var url = '/forums/' + forum_id + '/topics/' + topic_id + '.json';
            return $http.get(url)
                .then(function (response) {
                    $log.info('GET ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var newTopic = function (category_id, forum_id, subject, text) {
            var url = '/forums/' + forum_id + '/topics.json';
            var params = {
                category: category_id,
                subject: subject,
                text: text,
            };
            return $http.post(url, params)
                .then(function (response) {
                    $log.info('POST ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var deleteTopic = function (forum, id) {
            var url = '/forums/' + forum + '/topi©cs/' + id + '.json';
            return $http.delete(url)
                .then(function (response) {
                    $log.info('DELETE ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var editTopic = function (forum, id, subject) {
            var url = '/forums/' + forum + '/topics/' + id + '.json';
            return $http.put(url, {subject: subject})
                .then(function (response) {
                    $log.info('PUT ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var getPosts = function (topic_id) {
            var url = '/topics/' + topic_id + '/posts.json';
            return $http.get(url)
                .then(function (response) {
                    $log.info('GET ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var newPost = function (category, forum, topic_id, text, reply_to_post) {
            var url = '/topics/' + topic_id + '/posts.json';
            var params = {
                category: category,
                forum: forum,
                text: text,
                reply_to_post: reply_to_post,
            };
            return $http.post(url, params)
                .then(function (response) {
                    $log.info('post ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var deletePost = function (topic, id) {
            var url = '/topics/' + topic + '/posts/' + id + '.json';
            return $http.delete(url)
                .then(function (response) {
                    $log.info('DELETE ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        var editPost = function (topic, id, text) {
            var url = '/topics/' + topic + '/posts/' + id + '.json';
            return $http.put(url, {text: text})
                .then(function (response) {
                    $log.info('PUT ' + url + ' response', response);
                    return response.data;
                }, onError);
        };

        return {
            getCategoriesWithFavorites: getCategoriesWithFavorites,
            addUserFavorite: addUserFavorite,
            removeUserFavorite: removeUserFavorite,
            getForum: getForum,
            getTopicsWithFavorites: getTopicsWithFavorites,
            getTopic: getTopic,
            newTopic: newTopic,
            deleteTopic: deleteTopic,
            editTopic: editTopic,
            getPosts: getPosts,
            newPost: newPost,
            deletePost: deletePost,
            editPost: editPost,
        };
    };

    forum.service('ForumService', ['$http', '$log', '$q', forumService]);
}());