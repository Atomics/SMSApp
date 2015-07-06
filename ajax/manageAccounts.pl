#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use JSON -convert_blessed_universally;
use DBI;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

my $cgi        = CGI->new();
my @actionList = ('getAccountsList', 'getCurrentUser', 'deleteUser');
my $dbfile     = "../../database/sms.db";

print main();

sub main
{
    not header() and return result('code' => '420', 'msg' => 'Impossible to define header');
    not checkUser() and return result('code' => '403', 'msg' => 'Permission Denied');
    my $params = $cgi->Vars;

    if($params->{POSTDATA})
    {
        $params = decode_json($params->{POSTDATA});
    }

    if ( ! defined $params->{'action'} )
    {
        return result('code' => '404', 'msg' => 'Action is not define');
    }

    my $action = $params->{'action'};

    if ( ! grep $_ eq $action, @actionList )
    {
         return result('code' => '501', 'msg' => 'This ' . $action  . ' action doesn\'t exist');
    }
    
    no strict 'refs';
    my $fnret = &$action($params);
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
    my ($params) = @_;
    my $enable = $params->{'enable'};

    my $dsn = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });
    
    my $sql = 'SELECT id, username, comment, enable FROM accounts';
    my @dbParams = ();

    if( defined $enable )
    {
        if( $enable ne "1" and $enable ne "0" )
        {
       	    return result('code' => '400', 'msg' => 'Invalid Parameter Enable');
        }
        $sql .= " WHERE enable = ?";
        push(@dbParams, $enable);
    }

    my $sth = $dbh->prepare($sql);
    $sth->execute(@dbParams);

    my %accounts;
    while (my $row = $sth->fetchrow_hashref)
    {
        $accounts{$row->{'id'}} = {
            'username' => $row->{'username'},
            'comment'  => $row->{'comment'},
            'enable'   => $row->{'enable'},
        };
    }
    $dbh->disconnect();
    return result('code' => '200', 'msg' => \%accounts);
}

sub deleteUser
{
    my ($params) = @_;

    if( $cgi->request_method ne 'POST' )
    {
        return result('code' => '450', 'msg' => 'Invalid Method');        
    }

    my $userId = $params->{'userId'};
    if( not defined $userId or $userId !~ /^\d+$/ )
    {
        return result('code' => '400', 'msg' => 'Invalid Parameter userId');
    }

    my $dsn = "dbi:SQLite:dbname=$dbfile";
    my $dbh = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });
    
    my $sql = 'DELETE FROM accounts WHERE id = ?';

    my $sth = $dbh->prepare($sql);
    $sth->execute($userId);

    $dbh->disconnect();
    return result('code' => '200', 'msg' => 'User deleted !');
}
