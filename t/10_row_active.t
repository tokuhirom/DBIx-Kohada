use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Kohada;
use DBIx::Kohada::Schema;

{
    package MyApp::DB::Row::Foo;
    use parent qw/DBIx::Kohada::Row/;
    __PACKAGE__->set_table(qw/foo/);
    __PACKAGE__->set_primary_key(qw/id/);
    __PACKAGE__->add_column($_) for qw/id bar/;
}

my $dbh = DBI->connect('dbi:SQLite:', '', '', {PrintError => 0});
$dbh->do(q{create table foo (id integer not null primary key, bar)});
my $schema = DBIx::Kohada::Schema->new();
$schema->register_row_class('MyApp::DB::Row::Foo');
my $db = DBIx::Kohada->new(dbh => $dbh, schema => $schema);
my $foo = $db->insert(foo => {bar => "ORIGINAL"});
ok $foo;
isa_ok $foo, 'MyApp::DB::Row::Foo';
$foo->bar("OK");
is_deeply $foo->get_dirty_columns(), +{ bar => 'OK' };
$foo->update();
my $new_foo = $foo->refetch();
is $new_foo->bar(), 'OK';

done_testing;

