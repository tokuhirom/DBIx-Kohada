use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Kohada;
use DBIx::Kohada::Schema::Dumper;

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

{
    package MyApp::DB::Row::User;
    use parent qw/DBIx::Kohada::Row/;
}

# generate schema and eval.
my $code = DBIx::Kohada::Schema::Dumper->dump(
    dbh          => $dbh,
    table2class_cb => sub {
        is $_[0], 'user';
        return 'MyApp::DB::Row::User';
    },
);
my $schema = eval $code;
::ok !$@, 'no syntax error';
diag $@ if $@;

my $db = DBIx::Kohada->new(dbh => $dbh, schema => $schema);
my $user = $db->schema->table_name2row_class('user');
isa_ok $user, 'MyApp::DB::Row::User';
is($user->table, 'user');
is(join(',', @{$user->primary_key}), 'user_id');
is(join(',', $user->columns), 'user_id,name,email,created_on');

done_testing;

