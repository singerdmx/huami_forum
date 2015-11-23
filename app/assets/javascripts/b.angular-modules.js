/*
 Define angular modules as global variables.
 Note that the file starting with 'b' needs to be alphabetically prior to other js files.
 */
var forumAdmin = angular.module('forumAdmin', ['ngAnimate', 'ui.bootstrap']);

var forum = angular.module('forum', ['ngAnimate', 'ui.bootstrap', 'flow', 'ngClipboard']);