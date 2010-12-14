use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Kohada::Schema::Loader;

{
    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
    __PACKAGE__->load_plugin('Pager');
}

my $dbh = DBI->connect('dbi:SQLite:', '', '');
$dbh->do(q{create table foo (b int)}) or die;
my $schema = DBIx::Kohada::Schema::Loader->load(
    dbh            => $dbh,
    table2class_cb => sub {
        "MyApp::DB::Row::$_[0]";
    }
);
my $db = MyApp::DB->new(schema => $schema, dbh => $dbh);
my ($sql, @bind) = $db->query_builder->select('foo' => ['bar'], {});
is $sql, qq{SELECT "bar"\nFROM "foo"\n};

done_testing;

