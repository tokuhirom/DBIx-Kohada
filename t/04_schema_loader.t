use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;
use DBIx::Yakinny;
use DBIx::Yakinny::Schema::Loader;

{
    package MyApp::DB::Row::User;
    use Class::Accessor::Lite (
        new => 1,
        rw => [qw/user_id name email created_on/],
    );
}

# initialize
my $dbh = DBI->connect('dbi:SQLite:', '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    create table user (
        user_id integer primary key,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});

my $schema = DBIx::Yakinny::Schema::Loader->load(
    dbh => $dbh,
    table2class_cb => sub {
        is $_[0], 'user';
        return 'MyApp::DB::Row::User';
    },
);
my $db = DBIx::Yakinny->new(
    schema => $schema,
    dbh    => $dbh,
);
my $user = $db->schema->get_row_class_for('user');
is $user, 'MyApp::DB::Row::User';
my $table_info  = $db->schema->get_table_object_from_row_class('MyApp::DB::Row::User');
ok $table_info;
is($table_info->name, 'user');
is(join(',', @{$table_info->primary_key}), 'user_id');
is(join(',', $table_info->column_names), 'user_id,name,email,created_on');

done_testing;

