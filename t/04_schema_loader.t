use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Kohada;
use DBIx::Kohada::Schema::Loader;

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

my $schema = DBIx::Kohada::Schema::Loader->load(
    dbh => $dbh,
    table2class_cb => sub {
        is $_[0], 'user';
        return 'MyApp::DB::Row::User';
    },
);
my $db = DBIx::Kohada->new(
    schema => $schema,
    dbh    => $dbh,
);
my $user = $db->schema->table_name2row_class('user');
is $user, 'MyApp::DB::Row::User';
is($user->table, 'user');
is(join(',', @{$user->primary_key}), 'user_id');
is(join(',', $user->columns), 'user_id,name,email,created_on');

done_testing;

