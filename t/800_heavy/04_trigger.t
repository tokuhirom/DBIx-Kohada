use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBIx::Kohada::Schema;

plan tests => 11;

{
    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
}

{
    package MyApp::DB::Row::User;
    use parent qw/DBIx::Kohada::Row/;

    our $CNT = 0;

    __PACKAGE__->set_table('user');
    __PACKAGE__->set_primary_key('email');
    __PACKAGE__->add_column($_) for qw/name email token/;

    __PACKAGE__->add_trigger(
        'before_insert' => sub {
            my ($row_class, $val) = @_;
            ::is $row_class, 'MyApp::DB::Row::User';
            $val->{token} = 'HIJLK';
            $CNT++;
        },
    );

    __PACKAGE__->add_trigger(
        'after_insert' => sub {
            my ($row) = @_;
            ::isa_ok $row, 'MyApp::DB::Row::User';
            $row->{AFTER_INSERT_HOOK_OK} = 1;
            $CNT++;
        },
    );

    __PACKAGE__->add_trigger(
        'before_update' => sub {
            my ($row, $attr) = @_;
            ::isa_ok $row, 'MyApp::DB::Row::User';
            $attr->{name} = uc $attr->{name} if $attr->{name};
            $CNT++;
        }
    );
    __PACKAGE__->add_trigger(
        'after_update' => sub {
            my ($row, $attr) = @_;
            ::isa_ok $row, 'MyApp::DB::Row::User';
            $CNT++;
        }
    );

    __PACKAGE__->add_trigger(
        'before_delete' => sub {
            my ($row, $attr) = @_;
            ::isa_ok $row, 'MyApp::DB::Row::User';
            $CNT++;
        }
    );
    __PACKAGE__->add_trigger(
        'after_delete' => sub {
            my ($row, $attr) = @_;
            ::isa_ok $row, 'MyApp::DB::Row::User';
            $CNT++;
        }
    );
}

my $dbh = DBI->connect('dbi:SQLite:', '', '') or die;
$dbh->do(q{create table user (name text, email text PRIMARY KEY, token text);});

my $schema = DBIx::Kohada::Schema->new();
$schema->register_row_class('MyApp::DB::Row::User');

my $db = MyApp::DB->new(schema => $schema, dbh => $dbh);
my $row = $db->insert(user => {name => 'john', email => 'john@example.com'});
ok $row, 'returned row';
is $row->token, 'HIJLK';
ok $row->{AFTER_INSERT_HOOK_OK};

$row->set_columns({name => 'poo'});
$row->update();
$row = $row->refetch();
is $row->name, 'POO';

$row->delete();

is $MyApp::DB::Row::User::CNT, 6;


