use strict;
use warnings;
use Test::More;
use DBI;
use Test::Requires 'DBD::SQLite';
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;
use Storable;

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
my $user = $db->insert(user => {name => 'foo', email => 'foo@example.com'});
$user->update({email => 'bar@example.com'});
my $ice = Storable::nfreeze($user);
{
    $user = Storable::thaw($ice);
    eval { $user->refetch() };
    like $@, qr/There is no DBIx::Yakinny object in this instance/;
}
{
    local $DBIx::Yakinny::Row::thaw_yakinny = $db;
    $user = Storable::thaw($ice);
    ok $user->yakinny;
}

done_testing;

