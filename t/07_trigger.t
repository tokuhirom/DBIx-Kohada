use strict;
use warnings;
use Test::More;
use Test::Requires 'Class::Method::Modifiers', 'DBD::SQLite';
use DBIx::Yakinny::Schema;

plan tests => 8;

# pre_insert / post_insert / pre_update / post_update / pre_delete / post_delete

{
    package MyApp::DB;
    use parent qw/DBIx::Yakinny/;
    use Class::Method::Modifiers;

    our $cnt;

    before 'insert' => sub {
        my ($yakinny, $table, $val) = @_;
        ::is $table, 'user';
        $val->{token} = 'HIJLK';
    };
    around 'insert' => sub {
        my $code = shift;
        my $row = $code->(@_);
        $row->{AFTER_INSERT_HOOK_OK} = 1;
        return $row;
    };
    before 'update_row' => sub {
        my ($yakinny, $row, $attr) = @_;
        $attr->{name} = uc $attr->{name} if $attr->{name};
    };
    after 'update_row' => sub {
        my ($yakinny, $row, $attr) = @_;
        ::is $row->table, 'user';
    };
    before 'delete_row' => sub {
        my ($yakinny, $row) = @_;
        ::is $row->table, 'user';
    };
    after 'update_row' => sub {
        my ($yakinny, $row) = @_;
        ::is $row->table, 'user';
    };
}

{
    package MyApp::DB::Row::User;
    use parent qw/DBIx::Yakinny::Row/;
    __PACKAGE__->set_table('user');
    __PACKAGE__->add_column($_) for qw/name email token/;
    __PACKAGE__->set_primary_key('email');
}

my $dbh = DBI->connect('dbi:SQLite:', '', '') or die;
$dbh->do(q{create table user (name text, email text PRIMARY KEY, token text);});

my $schema = DBIx::Yakinny::Schema->new();
$schema->register_table('MyApp::DB::Row::User');

my $db = MyApp::DB->new(schema => $schema, dbh => $dbh);
my $row = $db->insert(user => {name => 'john', email => 'john@example.com'});
ok $row, 'returned row';
is $row->token, 'HIJLK';
ok $row->{AFTER_INSERT_HOOK_OK};

$row->update({name => 'poo'});
$row = $row->refetch();
is $row->name, 'POO';

$row->delete();


