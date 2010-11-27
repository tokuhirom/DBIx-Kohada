use strict;
use warnings;
use Test::More;
use Test::Requires 'Time::Piece', 'DBD::SQLite';
use DBI;
use t::Sweet;

# initialize
my $dbh = DBI->connect('dbi:SQLite:', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
TestSuite->run($dbh);


done_testing;

