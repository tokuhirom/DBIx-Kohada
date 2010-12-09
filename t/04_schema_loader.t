use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema::Loader;

{
    package MyApp::DB::Row::User;
    use parent qw/DBIx::Yakinny::Row/;
}

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

my $schema = DBIx::Yakinny::Schema::Loader->load(
    dbh => $dbh,
    table2class_cb => sub {
        is $_[0], 'user';
        return 'MyApp::DB::Row::User';
    },
);
my $db = DBIx::Yakinny->new(
    schema => $schema,
    dbh    => $dbh,
);
my $user = $db->schema->get_class_for('user');
is($user->table->name, 'user');
is(join(',', @{$user->primary_key}), 'user_id');
is(join(',', $user->table->columns), 'user_id,name,email,created_on');

done_testing;

