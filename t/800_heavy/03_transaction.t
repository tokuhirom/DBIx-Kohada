use strict;
use warnings;
use Test::More;
use DBIx::Kohada;
use DBIx::Kohada::Schema::Loader;
use Test::Requires 'DBD::SQLite';
use DBI;

{
    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
}

my $dbh = DBI->connect('dbi:SQLite:');
$dbh->do(q{CREATE TABLE foo (bar)});
my $schema = DBIx::Kohada::Schema::Loader->load(dbh => $dbh, table2class_cb => sub {
    local $_ = shift;
    "MyApp::DB::Row::$_";
});
my $db = MyApp::DB->new(dbh => $dbh, schema => $schema);
my $txn = $db->txn_scope();
$db->insert(foo => {bar => 'baz'});
is [$db->dbh->selectrow_array('SELECT COUNT(*) FROM foo')]->[0], 1;
$txn->rollback();

is [$db->dbh->selectrow_array('SELECT COUNT(*) FROM foo')]->[0], 0;

{
    my $txn = $db->txn_scope();
    $db->insert(foo => {bar => 'baz'});
    $txn->commit();
}

is [$db->dbh->selectrow_array('SELECT COUNT(*) FROM foo')]->[0], 1;

done_testing;

