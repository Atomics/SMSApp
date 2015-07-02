app.controller("MessageCtrl", function($rootScope, $scope, $routeParams, $filter, $translate, ngTableParams, Accounts, Messages){
    $scope.accountsList;
    $scope.messagesList = {};
    $scope.message;
    $scope.to;
    $scope.alerts = [];
    
 
    $scope.getMessagesList = function()
    {
        Messages.listMessages({
            action: 'getMessagesList'
        }, function success(data) {
            $scope.messagesList = data.msg;
        });
    };
    
    $scope.getAccountsList = function()
    {
        Accounts.getAccountsList({
            action: 'getAccountsList',
        },function success(data) {
            $scope.accountsList;
            if ( data.code == '200' )
            {
                $scope.accountsList = data.msg;
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
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.lists-accounts')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.list-accounts')});
        });
    };

    $scope.getMessagesList();

    $scope.getAccountsList();



    $scope.sendMessage= function()
    {
        $rootScope.closeAllAlerts(); 
        if ( ! $scope.to )
        {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.to-required')});
            return false;
        }
        
        if ( ! $scope.message )
        {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.message-required')});
            return false;
        }

        $scope.message = $scope.message.replace(/\n|\r/g, '. ');
        
        Messages.sendMessage({
            action: 'sendMessage',
            to:  $scope.to,
            message: $scope.message
        },function success(data) {
            if ( data.code == '200' )
            {
                $scope.respSendMessage = data.msg;
                $scope.resetForm();
                $rootScope.alerts.push({type: 'success', msg: $filter('translate')('ALERT.message-success')});
                return true;
            }
            else if ( data.code == '402' )
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.messages-toomuch')});
                return false;
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
            else if ( data.code == '412' )
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.missing-element')});
                return false;
            }
            else
            {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.messages-failed')});
                return false;
            }
        });
    }

    $scope.resetForm = function()
    {
        $scope.message = "";
        return true;
    }

});
