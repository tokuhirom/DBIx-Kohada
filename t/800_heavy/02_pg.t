use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::Pg', 'Test::postgresql';
use t::Sweet;

my $pg = Test::postgresql->new()
    or plan skip_all => $Test::postgresql::errstr;

my $dbh = DBI->connect( $pg->dsn(), '', '', {RaiseError => 1, Warn => 0}) or die "cannot connect to db";
$dbh->do(q{
    create table "user" (
        "user_id" serial primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
$dbh->do(q{
    create table entry (
        entry_id serial primary key,
        "user_id" int not null,
        body    text
    );
});
$dbh->do(q{
    create table good (
        entry_id integer,
        "user_id"  integer not null,
        PRIMARY KEY (entry_id, "user_id")
    );
});
TestSuite->run($dbh);

done_testing;

