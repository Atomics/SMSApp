app.factory('Accounts', function($resource) {
    return $resource('ajax/manageAccounts.pl', {}, {
        getAccountsList: { method:'GET'  , params: { action: 'action' }, isArray: false },
        getCurrentUser : { method:'GET'  , params: { action: 'action' }, isArray: false },
        deleteUser     : { method:'POST' , params: { action: 'action', userId: 'userId' }, isArray: false },
    });
});

app.factory('Messages', function($resource) {
    return $resource('ajax/manageMessages.pl', {}, {
        sendMessage:  { method:'GET', params: { action: 'action', to: 'to', message: 'message' }, isArray: false },
        listMessages: { method:'GET', params: { action: 'action' }, isArray: false },
    });
});
