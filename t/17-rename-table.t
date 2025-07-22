#! /usr/bin/env perl

use strict;
use warnings;

use DBI;
use Test::More tests => 9;

sub dbi_connect {
    DBI->connect(
        $ENV{DBI} || 'dbi:mysql:database=test;host=localhost;mysql_socket=/var/lib/mysql/mysql.sock',
        $ENV{DBI_USER} || 'root',
        $ENV{DBI_PASSWORD} || '',
    ) or die 'connection failed:';
}

my $dbh = dbi_connect();

# Clean up any existing tables
ok $dbh->do('drop table if exists q4m_old');
ok $dbh->do('drop table if exists q4m_new');

# Create a table with some data
ok $dbh->do('create table q4m_old (v1 int not null, v2 int not null) engine=queue');
ok $dbh->do("insert into q4m_old values (1,1), (2,2), (3,3)");

# Verify the data is there
is_deeply(
    $dbh->selectall_arrayref(q{select * from q4m_old order by v1}),
    [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ],
    'data exists before rename'
);

# Rename the table
ok $dbh->do('alter table q4m_old rename to q4m_new');

# Verify the old table doesn't exist
is_deeply(
    $dbh->selectall_arrayref(q{show tables like 'q4m_old'}),
    [],
    'old table name does not exist'
);

# Verify the new table exists and has the same data
is_deeply(
    $dbh->selectall_arrayref(q{select * from q4m_new order by v1}),
    [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ],
    'new table has the same data'
);

# Clean up
ok $dbh->do('drop table q4m_new');
