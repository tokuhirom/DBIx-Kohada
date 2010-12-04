use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny::Schema::Loader;

{
    package MyApp::DB;
    use base qw/DBIx::Yakinny/;
    __PACKAGE__->load_plugin('Pager');
}

my $dbh = DBI->connect('dbi:SQLite:', '', '');
$dbh->do(q{create table foo (b int)}) or die;
my $schema = DBIx::Yakinny::Schema::Loader->load(
    dbh            => $dbh,
    table2class_cb => sub {
        "MyApp::DB::Row::$_[0]";
    }
);
my $db = MyApp::DB->new(schema => $schema, dbh => $dbh);
my ($sql, @bind) = $db->query_builder->select('foo' => ['bar'], {});
is $sql, qq{SELECT "bar"\nFROM "foo"\n};

done_testing;

