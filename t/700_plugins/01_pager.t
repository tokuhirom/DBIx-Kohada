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
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 1;
    is $pager->next_page, 2, 'next_page';
    ok $pager->has_next, 'has_next';
    is $pager->prev_page, undef;
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_with_pager(foo => {}, {rows => 3, page => 11});
    is join(',', map { $_->b } @$rows), '31,32';
    is $pager->entries_per_page(), 3;
    is $pager->current_page(), 11;
    is $pager->next_page, undef, 'next_page';
    ok !$pager->has_next, 'has_next';
    is $pager->prev_page, 10;
};

done_testing;

