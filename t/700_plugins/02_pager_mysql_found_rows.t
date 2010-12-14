use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::mysql', 'Test::mysqld';
use DBI;
use DBIx::Kohada::Schema::Loader;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',    # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

{
    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
    __PACKAGE__->load_plugin('Pager::MySQLFoundRows');
}

my $dbh = DBI->connect($mysqld->dsn);
$dbh->do(q{create table foo (b integer not null) TYPE=InnoDB}) or die;
my $schema = DBIx::Kohada::Schema::Loader->load(dbh => $dbh, table2class_cb => sub {
    "MyApp::DB::Row::$_[0]"
});
my $db = MyApp::DB->new(schema => $schema, dbh => $dbh);
for my $i (1..32) {
    $db->insert(foo => { b => $i++ });
}

subtest 'simple' => sub {
    my ($rows, $pager) = $db->search_with_pager(foo => {}, {rows => 3, page => 1});
    is join(',', map { $_->b } @$rows), '1,2,3';
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    is $pager->previous_page, undef;
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_with_pager(foo => {}, {rows => 3, page => 11});
    is join(',', map { $_->b } @$rows), '31,32';
    is $pager->total_entries(), 32;
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 11;
    is $pager->next_page, undef, 'next_page';
    is $pager->previous_page, 10;
};

done_testing;


