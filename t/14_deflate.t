use strict;
use warnings;
use Test::More;
use DBI;
use Test::Requires 'Time::Piece', 'DBD::SQLite';
use Time::Piece;
use DBIx::Kohada::Schema;
use DBIx::Kohada;

{
    package MyApp::DB::Row::User;
    use parent qw/DBIx::Kohada::Row/;
    __PACKAGE__->set_inflation_rule(
        ctime => sub {
            ::note 'inflate';
            Time::Piece->new($_[0])
        }
    );
    __PACKAGE__->set_deflation_rule(
        ctime => sub { $_[0]->epoch }
    );
    __PACKAGE__->set_table(qw/user/);
    __PACKAGE__->set_primary_key(qw/id/);
    __PACKAGE__->add_column($_) for qw/id name ctime/;
}

my $schema = DBIx::Kohada::Schema->new();
$schema->register_row_class('MyApp::DB::Row::User');

my $dbh = DBI->connect('dbi:SQLite:', '', '', {RaiseError => 1});
$dbh->do(q{create table user (id integer primary key, name, ctime)});
my $db = DBIx::Kohada->new(dbh => $dbh, schema => $schema);
my $user = $db->insert(user => {name => 'john', ctime => Time::Piece->new(1292044372)});
$user = $user->refetch;
is $user->get_column('ctime'), '1292044372';
isa_ok $user->ctime, 'Time::Piece';
$user->update({ctime => Time::Piece->new(1100000000)});
$user = $user->refetch;
is $user->get_column('ctime'), '1100000000';
isa_ok $user->ctime, 'Time::Piece';
$user->update({ctime => \"ctime + 1"});
$user = $user->refetch;
is $user->get_column('ctime'), '1100000001';
$user = $db->insert(user => {id => $user->id, ctime => Time::Piece->new(528279795)}, {prefix => 'REPLACE '});
is $user->get_column('ctime'), '528279795';

done_testing;

