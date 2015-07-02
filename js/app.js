var validLanguage = new Array('en','fr','zh');

var elementsShared = angular.module( 'elementsShared', [] );

elementsShared.directive('ngBlur', ['$parse', function($parse) {
    return function(scope, element, attr) {
        var fn = $parse(attr['ngBlur']);
        element.on('blur', function(event) {
            scope.$apply(function() {
                fn(scope, {$event:event});
            });
        });
    };
}]);

var app = angular.module('myApp', [
			  'ngRoute',
                          'ngResource',
                          'ngTable',
			  'pascalprecht.translate',
                          'ui.bootstrap',
                          'elementsShared',
		  ]);
		  
app.config(['$routeProvider', function($routeProvider) {
	$routeProvider.when('/home',            {templateUrl: 'template/home.html',                                      });
	$routeProvider.when('/send-message',    {templateUrl: 'template/send-message.html',    controller: 'MessageCtrl' });
	$routeProvider.when('/list-messages',   {templateUrl: 'template/list-messages.html',   controller: 'MessageCtrl' });
	$routeProvider.when('/accounts',        {templateUrl: 'template/accounts.html',        controller: 'AccountCtrl' });
	$routeProvider.when('/about',           {templateUrl: 'template/about.html'                                      });
	$routeProvider.otherwise({redirectTo: '/home'});
}]);

app.config(['$translateProvider', function($translateProvider){
	$translateProvider.useStaticFilesLoader({
		prefix: '/languages/',
		suffix: '.json'
	});
	$translateProvider.determinePreferredLanguage(function () {
		var language = window.navigator.userLanguage || window.navigator.language;
		language = language.substring(0, 2);
		if( validLanguage.indexOf(language) != -1 ) {
			return language;
		}
		return 'en';
	});
}]);

app.run(function($rootScope, $location, $translate) {
    $rootScope.alerts = [];	
    $rootScope.navActive = function(path) {
            if ( $location.path() == path ) {
                    return true;
            } else {
                    return false;
            }
    }
        	
    $rootScope.getCurrentUser = function()
    {
        Accounts.getCurrentUser({
            action: 'getCurrentUser',
        },function success(data) {
            $scope.accountsList;
            if ( data.code == '200' )
            {
                $rootScope.currentUser = data.msg;
                return true;
            }
            else if ( data.code == '403' )
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' )
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.user-current')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.user-current')});
        });    
    };
    
    $rootScope.closeAlert = function(index) {
        $rootScope.alerts.splice(index, 1);
    };

    $rootScope.closeAllAlerts = function() {
        angular.forEach($rootScope.alerts, function(value, key) {
               $rootScope.closeAlert(key);
        });
    };

    $rootScope.changeLanguage = function (langKey) {
            $translate.use(langKey);
    };
    
    $rootScope.activeLanguage = function (langKey) {
            if ( $translate.use() == langKey ) {
                    return true;
            } else {
                    return false;
            }
    };
});


