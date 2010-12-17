use strict;
use warnings;
use Test::More;
use Test::Requires 'Time::Piece', 'DBD::SQLite';
use DBI;
use t::Sweet;
use DBIx::Kohada;

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
$dbh->do(q{
    create table entry (
        entry_id integer primary key,
        user_id int not null,
        body    text
    );
});
$dbh->do(q{
    create table good (
        entry_id integer,
        user_id  integer not null,
        PRIMARY KEY (entry_id, user_id)
    );
});
subtest 'suite' => sub {
    TestSuite->run($dbh);
};

subtest 'replace' => sub {
    my $schema = TestSuite->make_schema();
    my $db = DBIx::Kohada->new(schema => $schema, dbh => $dbh);
    $db->insert(user => {user_id => 99, name => 'john'});
    $db->insert(user => {user_id => 99, name => 'man'}, {prefix => 'REPLACE '});
    my @user = $db->search(user => {user_id => 99});
    is scalar(@user), 1;
    is $user[0]->name, 'man';
};

done_testing;

