use strict;
use warnings;
use Test::More;
use Test::Requires 'Time::Piece', 'DBD::SQLite';
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;

my $schema = DBIx::Yakinny::Schema->new();
$schema->register_table(
    table   => 'user',
    columns => [qw/user_id name email created_on/],
    primary_key      => 'user_id',
);

my $dbh = DBI->connect('dbi:SQLite:', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);
$db->insert(user => {name => 'foo', email => 'foo@example.com'});
is $db->last_insert_id, 1, 'insert,last_insert_id';
my $user = $db->single(user => {user_id => 1});
isa_ok $user, 'DBIx::Yakinny::Schema::AnonRow::0';
isa_ok $user, 'DBIx::Yakinny::Row';

done_testing;

