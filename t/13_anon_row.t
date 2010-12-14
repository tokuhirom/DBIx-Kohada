use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBIx::Kohada::Schema;
use DBIx::Kohada;
use DBIx::Kohada::Schema::Loader;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:', '', '') or die;
$dbh->do(q{create table a (b)});
my $schema = DBIx::Kohada::Schema::Loader->load(dbh => $dbh, table2class_cb => sub {
    "MyApp::DB::Row::$_[0]"
});
my $db = DBIx::Kohada->new(schema => $schema, dbh => $dbh);
for (1..10) {
    $db->insert(a => {b => $_});
}
my @rows = $db->search_by_sql(undef, 'SELECT * FROM a');
is scalar(@rows), 10;
my $row = $rows[0];
ok $row;
isa_ok $row, 'DBIx::Kohada::AnonRow';
is join(',', sort $row->columns()), 'b';
is $row->b, 1;

subtest "exception when it's not selected field" => sub {
    eval { $row->c };
    ok $@;
    like $@, qr/'c' was not fetched by query./;
};

is_deeply $row->get_columns, +{b=> 1};

done_testing;

