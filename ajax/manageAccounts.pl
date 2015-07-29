#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use JSON -convert_blessed_universally;
use DBI;
use CGI::Carp 'fatalsToBrowser';
use Data::Dumper;

my $cgi        = CGI->new();
my @actionList = ('getAccountsList', 'getCurrentUser', 'deleteUser', 'editUser', 'createUser');
my $dbfile     = "../../database/sms.db";

my %schema = (
    'id' => {
        'type'     => 'integer',
        'editable' => 0,
    },
    'username' => {
        'type'     => 'integer',
        'editable' => 1,
    },
    'comment' => {
        'type'     => 'string',
        'editable' => 1,
    },
    'enable' => {
        'type' => 'bool',
        'editable' => 1,
    },
    'apikey' => {
        'type'     => 'string',
        'editable' => 1,
    }
);

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

sub editUser
{
    my ($params) = @_;
    
    if( $cgi->request_method ne 'POST' )
    {
        return result('code' => '450', 'msg' => 'Invalid Method');        
    }

    if( not defined $params->{'user'} )
    {
        return result('code' => '412', 'msg' => 'Missing Parameter user');
    }

    my %user   = %{$params->{'user'}};
    my $userId = $user{'id'};
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

    my $sql = "UPDATE accounts SET ";
    my @sqlParams = ();
    my @errors = ();

    foreach my $field ( keys %user )
    {
        if( not defined $schema{$field} )
        {
            push(@errors, 'Field ' . $field . ' does not exist...');
            next;
        }
        if( not $schema{$field}{'editable'} )
        {
            next;
        }
        if( $user{$field} eq '' )
        {
            push(@errors, 'Field ' . $field . ' cannot be empty...');
            next;
        }
        elsif( $schema{$field}{'type'} eq 'integer' and $user{$field} !~ /^\d+$/ )
        {
            push(@errors, 'Field ' . $field . ' should be an integer...');
            next;
        }
        elsif( $schema{$field}{'type'} eq 'bool' and $user{$field} !~ /^(0|1)$/ )
        {
            push(@errors, 'Field ' . $field . ' should be a boolean...');
            next;
        }
        $sql .= $field . ' = ? ,' ;
        push(@sqlParams, $user{$field});
    }

    $sql = substr($sql, 0, -1);

    $sql .= "WHERE id = ?";
    push(@sqlParams, $user{'id'});
        
    if( scalar(@errors) )
    {
        return result('code' => '500', 'msg' => @errors);
    }
    
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sqlParams);

    $dbh->disconnect();
    return result('code' => '200', 'msg' => 'User edited !');
}

sub createUser
{
    my ($params) = @_;
    
    if( $cgi->request_method ne 'POST' )
    {
        return result('code' => '450', 'msg' => 'Invalid Method');        
    }

    if( not defined $params->{'user'} )
    {
        return result('code' => '412', 'msg' => 'Missing Parameter user');
    }

    my %user = %{$params->{'user'}}; 
    my $dsn  = "dbi:SQLite:dbname=$dbfile";
    my $dbh  = DBI->connect($dsn, "", "", {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
    });

    my $sql       = "INSERT INTO accounts(";
    my @listField = ();
    my @sqlParams = ();
    my @errors    = ();

    foreach my $field ( keys %user )
    {
        if( not defined $schema{$field} )
        {
            push(@errors, 'Field ' . $field . ' does not exist...');
            next;
        }
        if( not $schema{$field}{'editable'} )
        {
            next;
        }
        if( $user{$field} eq '' )
        {
            push(@errors, 'Field ' . $field . ' cannot be empty...');
            next;
        }
        elsif( $schema{$field}{'type'} eq 'integer' and $user{$field} !~ /^\d+$/ )
        {
            push(@errors, 'Field ' . $field . ' should be an integer...');
            next;
        }
        elsif( $schema{$field}{'type'} eq 'bool' and $user{$field} !~ /^(0|1)$/ )
        {
            push(@errors, 'Field ' . $field . ' should be a boolean...');
            next;
        }
        
        push(@listField, $field);
        push(@sqlParams, $user{$field});
    }

    $sql .= join(',', @listField) . ') VALUES (';

    foreach my $valueField ( @listField )
    {
        $sql .= ' ?,';
    }
    $sql = substr($sql, 0, -1);

    $sql .= ")";
        
    if( scalar(@errors) )
    {
        return result('code' => '500', 'msg' => @errors);
    }
    
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sqlParams);

    $dbh->disconnect();
    return result('code' => '200', 'msg' => 'User created !');
}
