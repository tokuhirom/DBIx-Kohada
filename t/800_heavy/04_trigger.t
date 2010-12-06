use strict;
use warnings;
use Test::More;
use Test::Requires 'Class::Method::Modifiers', 'DBD::SQLite';
use DBIx::Yakinny::Schema;

plan tests => 15;

{
    package MyApp::DB;
    use parent qw/DBIx::Yakinny/;
    use Class::Method::Modifiers;

    __PACKAGE__->load_plugin('Trigger');

    our $CNT = 0;

    __PACKAGE__->add_trigger(
        'user' => 'before_insert' => sub {
            my ($yakinny, $val) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            $val->{token} = 'HIJLK';
            $CNT++;
        },
    );

    __PACKAGE__->add_trigger(
        'user' => 'after_insert' => sub {
            my ($yakinny, $row) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            $row->{AFTER_INSERT_HOOK_OK} = 1;
            $CNT++;
        },
    );

    __PACKAGE__->add_trigger(
        'user' => 'before_update' => sub {
            my ($yakinny, $row, $attr) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            ::isa_ok $row, 'DBIx::Yakinny::Row';
            $attr->{name} = uc $attr->{name} if $attr->{name};
            $CNT++;
        }
    );
    __PACKAGE__->add_trigger(
        'user' => 'after_update' => sub {
            my ($yakinny, $row, $attr) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            ::isa_ok $row, 'DBIx::Yakinny::Row';
            $CNT++;
        }
    );

    __PACKAGE__->add_trigger(
        'user' => 'before_delete' => sub {
            my ($yakinny, $row, $attr) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            ::isa_ok $row, 'DBIx::Yakinny::Row';
            $CNT++;
        }
    );
    __PACKAGE__->add_trigger(
        'user' => 'after_delete' => sub {
            my ($yakinny, $row, $attr) = @_;
            ::isa_ok $yakinny, 'DBIx::Yakinny';
            ::isa_ok $row, 'DBIx::Yakinny::Row';
            $CNT++;
        }
    );
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

$db->update($row, {name => 'poo'});
$row = $db->refetch($row);
is $row->name, 'POO';

$db->delete($row);

is $MyApp::DB::CNT, 6;

