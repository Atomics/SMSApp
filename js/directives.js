angular.module('myApp.directives', []).directive('bsNavbar', ['$location', function ($location) {
    return {
        restrict: 'A',
        link: function postLink(scope, element) {
            scope.$watch(function () {
                return $location.path();
            }, function (path) {
                angular.forEach(element.children(), (function (li) {
                    var $li = angular.element(li),
                    regex = new RegExp('^' + $li.attr('data-match-route') + '$', 'i'),
                    isActive = regex.test(path);
                    $li.toggleClass('active', isActive);
                }));
            });
        }
    };
}]);
