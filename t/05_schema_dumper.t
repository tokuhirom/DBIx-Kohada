use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema::Dumper;

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
    # generate schema and eval.
    my $code = DBIx::Yakinny::Schema::Dumper->dump(
        dbh          => $dbh,
        schema_class => 'MyApp::DB::Schema',
    );
    eval $code;
    ::ok !$@, 'no syntax error';
}

my $db = DBIx::Yakinny->new(dbh => $dbh, schema => 'MyApp::DB::Schema');
my $user = $db->schema->get_class_for('user');
is($user->table, 'user');
is(join(',', @{$user->primary_key}), 'user_id');
is(join(',', $user->columns), 'user_id,name,email,created_on');

done_testing;

