use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;

{
    package MyApp::DB::Row::Foo;
    use parent qw/DBIx::Yakinny::Row/;
    __PACKAGE__->set_table(qw/foo/);
    __PACKAGE__->add_column(qw/bar/);
}

my $dbh = DBI->connect('dbi:SQLite:', '', '', {PrintError => 0});
my $schema = DBIx::Yakinny::Schema->new();
$schema->register_row_class('MyApp::DB::Row::Foo');
my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);
eval {$db->single(foo => {foo_id => 1})};
like($@, qr{t/09_exception.t}) or diag $@;

done_testing;

