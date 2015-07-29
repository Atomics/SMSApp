app.controller("MessageCtrl", function($rootScope, $scope, $routeParams, $filter, $translate, Accounts, Messages){
    $scope.accountsList;
    $scope.messagesList = {};
    $scope.message;
    $scope.to;
    $scope.alerts = [];
    
 
    $scope.getMessagesList = function() {
        Messages.listMessages({
            action: 'getMessagesList'
        }, function success(data) {
            $scope.messagesList = data.msg;
        });
    };
    
    $scope.getAccountsList = function() {
        Accounts.getAccountsList({
            action: 'getAccountsList',
            enable: '1',
        },function success(data) {
            $scope.accountsList;
            if ( data.code == '200' ) {
                $scope.accountsList = data.msg;
                return true;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.lists-accounts')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.list-accounts')});
        });
    };

    $scope.sendMessage= function() {
        $rootScope.closeAllAlerts(); 
        if ( ! $scope.to ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.to-required')});
            return false;
        }
        
        if ( ! $scope.message ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.message-required')});
            return false;
        }

        $scope.message = $scope.message.replace(/\n|\r/g, '. ');
        
        Messages.sendMessage({
            action: 'sendMessage',
            to:  $scope.to,
            message: $scope.message
        },function success(data) {
            if ( data.code == '200' ) {
                $scope.respSendMessage = data.msg;
                $scope.resetForm();
                $rootScope.alerts.push({type: 'success', msg: $filter('translate')('ALERT.message-success')});
                return true;
            }
            else if ( data.code == '402' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.messages-toomuch')});
                return false;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else if ( data.code == '412' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.missing-element')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.messages-failed')});
                return false;
            }
        });
    }

    $scope.resetForm = function() {
        $scope.message = "";
        return true;
    }

    $scope.getMessagesList();
    $scope.getAccountsList();
});

app.controller("AccountCtrl", function($rootScope, $scope, $routeParams, $filter, $translate, Accounts, Messages ){
    $scope.accountsList = {};
    $scope.alerts = [];
    $scope.action = '';
    $scope.actionUser = new Object();
    
    $scope.getAccountsList = function() {
        Accounts.getAccountsList({
            action: 'getAccountsList',
        },function success(data) {
            $scope.accountsList;
            if ( data.code == '200' ) {
                $scope.accountsList = data.msg;
                return true;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.lists-accounts')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.list-accounts')});
             return false;
        });
    };
    
    $scope.showHistories = function(id) {
        if( angular.isUndefined($scope.accountsList[id]) ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
            return false;
        }

        $scope.action = 'showHistories';
        
        $scope.actionUser = $scope.accountsList[id];
        $scope.actionUser.id = id;
        
        Messages.listMessages({
            action:   'getMessagesList',
            username: $scope.actionUser.comment
        }, function success(data) {
            $scope.userMessagesList = data.msg;
            $('#messagesHistories').modal('show');
        });
    };

    $scope.showUser = function(id) {
        $scope.action = 'show';
        
        $scope.actionUser = $scope.accountsList[id];
        $scope.actionUser.id = id;
        
        $('#manageUser').modal('show');
    };

    $scope.editUser = function(id) {
        $scope.action = 'edit';
        
        $scope.actionUser = $scope.accountsList[id];
        $scope.actionUser.id = id;
        
        $('#manageUser').modal('show');
    };
    
    $scope.createUser = function(id) {
        $scope.action = 'create';
        
        $scope.actionUser = new Object();
        
        $('#manageUser').modal('show');
    };


    $scope.deleteUser = function(id) {
        if( angular.isUndefined($scope.accountsList[id]) ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
            return false;
        }

        $scope.action = 'delete';

        $scope.actionUser = $scope.accountsList[id];
        $scope.actionUser.id = id;

        $('#deleteUser').modal('show');
    };

    $scope.updateUser = function() {
        if( angular.isUndefined($scope.actionUser) || Object.keys($scope.actionUser).length == 0 ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
            return false;
        }
        
        if( angular.isUndefined($scope.action) || $scope.action != 'edit' ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
            return false;
        }
        
        Accounts.updateUser({
            action: $scope.action + 'User',
            user:   $scope.actionUser,
        },function success(data) {
            if ( data.code == '200' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.edit-success')});
                $scope.getAccountsList();
                $('#manageUser').modal('hide');
                return true;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
             return false;
        });
    };
    
    $scope.actionCreateUser = function() {
        if( angular.isUndefined($scope.action) || $scope.action != 'create' ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
            return false;
        }
        
        Accounts.updateUser({
            action: $scope.action + 'User',
            user:   $scope.actionUser,
        },function success(data) {
            if ( data.code == '200' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.edit-success')});
                $scope.getAccountsList();
                $('#manageUser').modal('hide');
                return true;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
             return false;
        });
    };

    $scope.actionDeleteUser = function() {
        if( angular.isUndefined($scope.actionUser) || Object.keys($scope.actionUser).length == 0 ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
            return false;
        }
        
        if( angular.isUndefined($scope.action) || $scope.action != 'delete' ) {
            $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
            return false;
        }
        
        Accounts.deleteUser({
            action: $scope.action + 'User',
            userId: $scope.actionUser.id
        },function success(data) {
            if ( data.code == '200' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.delete-success')});
                $scope.getAccountsList();
                $('#deleteUser').modal('hide');
                return true;
            }
            else if ( data.code == '403' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.permissions-denied')});
                return false;
            }
            else if ( data.code == '404' ) {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.not-found')});
                return false;
            }
            else {
                $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
                return false;
            }
        },function error(data) {
             $rootScope.alerts.push({type: 'danger', msg: $filter('translate')('ALERT.unknown')});
             return false;
        });
    };

    $('#deleteUser').on('hidden.bs.modal', function (e){
        $scope.action = '';
        $scope.actionUser = new Object();
    });
    
    $('#manageUser').on('hidden.bs.modal', function (e){
        $scope.action = '';
        $scope.actionUser = new Object();
    });
    
    $('#messagesHistories').on('hidden.bs.modal', function (e){
        $scope.action = '';
        $scope.actionUser = new Object();
    });

    $scope.getAccountsList();
});
