#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use JSON;
use DBI;
use LWP::UserAgent;
use IO::Socket::SSL qw();
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

my $cgi        = CGI->new();
my @actionList = ('sendMessage', 'getMessagesList');
my $dbfile     = "../../database/sms.db";

print main();

sub main
{
    not header() and return result('code' => '420', 'msg' => 'Impossible to define header');
    not checkUser() and return result('code' => '403', 'msg' => 'Permission Denied');
   
    if ( ! defined $cgi->url_param('action') )
    {
        return result('code' => '404', 'msg' => 'Action is not define');
    }
    my $action = $cgi->url_param('action');
    
    if ( ! grep $_ eq $action, @actionList )
    {
         return result('code' => '501', 'msg' => 'This action doesn\'t exist');
    }
    
    no strict 'refs';
    my $fnret = &$action();
    if ( ! defined $fnret->{'code'})
    {
        print $fnret
    }
    else
    {
        return result('code' => $fnret->{'code'}, 'msg' => $fnret->{'msg'});
    }
    
    not footer() and return result('code' => '420', 'msg' => 'Impossible to define footer');
}

sub result
{
    my %params = @_;
    my $msg = $params{'msg'} || "No message define";

    if ( ! defined $params{'code'} )
    {
        my $result = {"code" => "420", "msg" => "You didn't define a code result"};
        return to_json($result);
    }
    my $result = {"code" => $params{'code'}, "msg" => $msg};
    return to_json($result, {  pretty => 1 });
}

sub header
{
    print $cgi->header(-type => 'application/json',
                       -charset => 'utf-8');
                   
    return 1;
}

sub footer
{
    return 1;
}

sub checkUser
{
    if( ! defined $cgi->remote_user() )
    {
        return 0;
    }
    return 1;
}

sub sendMessage
{
    if ( ! defined $cgi->param('to') )
    {
        return {'code' => '412', 'msg' => 'This action need to receive a "to" value'};
    }
    
    if ( ! defined $cgi->param('message') )
    {
        return {'code' => '412', 'msg' => 'This action need to receive a "message" value'};
    }
    
    my $dsn = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });

    my $sql = 'SELECT username, apikey, comment FROM accounts WHERE username = ? and enable = ?';
    my $sth = $dbh->prepare($sql);
    $sth->execute($cgi->param('to') , 1);
    my $user = $sth->fetchrow_hashref;

    my $t = localtime;

    $sql = "INSERT INTO messages ('username', 'to', 'message', 'date') VALUES (?, ?, ?, ?)";
    $sth = $dbh->prepare($sql);
    $sth->execute($cgi->remote_user(), $user->{'comment'}, $cgi->param('message'), $t);

    $dbh->disconnect();
    
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
    $ua->ssl_opts( SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, SSL_hostname => '', verify_hostname => 0 );
    my $url = 'https://smsapi.free-mobile.fr/sendmsg?user=' . $user->{'username'} . '&pass=' . $user->{'apikey'} . '&msg=' . $cgi->remote_user() . ': ' . $cgi->param('message');
    my $resp = $ua->get($url);
    
    
    if ( $resp->code eq '200' )
    {
        return result('code' => '200', 'msg' => 'Message send !');
    }
    elsif ( $resp->code eq '400' )
    {
        return result('code' => '412', 'msg' => 'Missing Parameters');
    }
    elsif ( $resp->code eq '402' )
    {
        return result('code' => '402', 'msg' => 'Too much message was send. Try again later');
    }
    elsif ( $resp->code eq '403' )
    {
        return result('code' => '403', 'msg' => 'Permission Denied');
    }
    else
    {
        return result('code' => '500', 'msg' => 'Server error');
    }
}

sub getMessagesList
{
    my $username = $cgi->url_param('username');
    
    my $dsn = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });

    my $sql = 'SELECT * FROM messages LIMIT 500';
    my @sqlParams = ();
    if( defined $username )
    {
        $sql .= ' WHERE to = ?';
        push( @sqlParams, $username );
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sqlParams);
    my %messages;
    while (my $row = $sth->fetchrow_hashref)
    {
        $messages{$row->{'id'}} = {
            'username' => $row->{'username'},
            'to'       => $row->{'to'},
            'message'  => $row->{'message'},
            'date'     => $row->{'date'},
        };
    }
    $dbh->disconnect();
    return result('code' => '200', 'msg' => \%messages);
}
