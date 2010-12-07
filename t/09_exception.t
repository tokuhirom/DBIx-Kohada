use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;
use DBIx::Yakinny::Schema::Table;

{
    package MyApp::DB::Row::Foo;
    use base qw/DBIx::Yakinny::Row/;
}

my $dbh = DBI->connect('dbi:SQLite:', '', '', {PrintError => 0});
my $schema = DBIx::Yakinny::Schema->new();
my $table = DBIx::Yakinny::Schema::Table->new(
    name => 'foo',
);
$table->add_column($_) for qw/foo_id/;
$schema->map_table($table, 'MyApp::DB::Row::Foo');
my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);
eval {$db->single(foo => {foo_id => 1})};
like($@, qr{t/09_exception.t}) or diag $@;

done_testing;

