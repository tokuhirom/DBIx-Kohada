use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;

{
    package MyApp::DB::Row::Foo;
    use parent qw/DBIx::Yakinny::Row::Active/;
}

my $dbh = DBI->connect('dbi:SQLite:', '', '', {PrintError => 0});
$dbh->do(q{create table foo (id integer not null primary key, bar)});
my $schema = DBIx::Yakinny::Schema->new();
my $table = DBIx::Yakinny::Table->new(
    name => 'foo',
    primary_key => [qw/id/],
);
$table->add_column($_) for qw/id bar/;
$schema->register_table($table => 'MyApp::DB::Row::Foo');
my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);
my $foo = $db->insert(foo => {bar => "ORIGINAL"});
ok $foo;
isa_ok $foo, 'MyApp::DB::Row::Foo';
$foo->bar("OK");
is_deeply $foo->get_dirty_columns(), +{ bar => 'OK' };
$foo->update();
my $new_foo = $foo->refetch();
is $new_foo->bar(), 'OK';

done_testing;

