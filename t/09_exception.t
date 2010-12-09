use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema;

{
    package MyApp::DB::Row::Foo;
    use base qw/DBIx::Yakinny::Row/;
    my $table = DBIx::Yakinny::Table->new(
        name => 'foo',
    );
    __PACKAGE__->set_table($table);
}

my $dbh = DBI->connect('dbi:SQLite:', '', '', {PrintError => 0});
my $schema = DBIx::Yakinny::Schema->new();
$schema->register_table('MyApp::DB::Row::Foo');
my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);
eval {$db->single(foo => {foo_id => 1})};
like($@, qr{t/09_exception.t}) or diag $@;

done_testing;

