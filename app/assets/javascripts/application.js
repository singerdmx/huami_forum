// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require forem
//= require_tree .
//= require bootstrap.min
//= require jquery.timeago
//= require angular
//= require angular-animate
//= require angular-resource
//= require ui-bootstrap-tpls-0.14.2
//= require forum
//= require forum-admin
//= require ckeditor/ckeditor


var toggleFullQuote = function (element) {
    $(element).hide();
    $(element).parent().children('div.quote').last().show();
};