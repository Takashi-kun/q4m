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

sub get_data_dir {
    my $dbh = shift;
    my $result = $dbh->selectall_arrayref("SHOW VARIABLES LIKE 'datadir'");
    return $result->[0]->[1];
}

sub check_file_exists {
    my ($data_dir, $db_name, $table_name, $ext) = @_;
    my $file_path = "$data_dir/$db_name/$table_name$ext";
    return -f $file_path;
}

my $dbh = dbi_connect();

# Get the data directory
my $data_dir = get_data_dir($dbh);
my $db_name = 'test';  # Assuming we're using the 'test' database

# Clean up any existing tables
ok $dbh->do('drop table if exists q4m_rename_test');
ok $dbh->do('drop table if exists q4m_renamed_test');

# Create a table with some data
ok $dbh->do('create table q4m_rename_test (v1 int not null) engine=queue');
ok $dbh->do("insert into q4m_rename_test values (1), (2), (3)");

# Verify the .Q4M file exists for the original table
ok(check_file_exists($data_dir, $db_name, 'q4m_rename_test', '.Q4M'),
   'Q4M file exists before rename');

# Rename the table
ok $dbh->do('alter table q4m_rename_test rename to q4m_renamed_test');

# Verify the .Q4M file exists for the renamed table
ok(check_file_exists($data_dir, $db_name, 'q4m_renamed_test', '.Q4M'),
   'Q4M file exists after rename');

# Verify the old .Q4M file doesn't exist
ok(!check_file_exists($data_dir, $db_name, 'q4m_rename_test', '.Q4M'),
   'Old Q4M file does not exist after rename');

# Clean up
ok $dbh->do('drop table q4m_renamed_test');
