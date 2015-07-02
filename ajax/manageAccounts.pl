#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use JSON;
use DBI;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

my $cgi        = CGI->new();
my @actionList = ('getAccountsList', 'getCurrentUser');
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
    my $fnret = &$action($cgi->{'param'});
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

sub getCurrentUser
{
    return result('code' => '200', 'msg' => $cgi->remote_user());
}

sub getAccountsList
{
    my $dsn = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });

    my $sql = 'SELECT id, username, apikey, comment FROM accounts WHERE enable = ?';
    my $sth = $dbh->prepare($sql);
    $sth->execute(1);
    my %accounts;
    while (my $row = $sth->fetchrow_hashref)
    {
        $accounts{$row->{'id'}} = {
            'username' => $row->{'username'},
            'comment'  => $row->{'comment'},
        };
    }
    $dbh->disconnect();
    return result('code' => '200', 'msg' => \%accounts);
}
