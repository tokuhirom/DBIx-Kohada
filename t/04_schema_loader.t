use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;

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

{
    package MyApp::DB;
    use base qw/DBIx::Yakinny/;
    use DBIx::Yakinny::Schema::Loader;

    __PACKAGE__->set_schema_class(
        DBIx::Yakinny::Schema::Loader->load(
            dbh => $dbh
        )
    );
}

my $db = MyApp::DB->new(dbh => $dbh);
my $user = $db->schema_class->get_class_for('user');
is($user->table, 'user');
is(join(',', @{$user->pk}), 'user_id');
is(join(',', $user->columns), 'user_id,name,email,created_on');

done_testing;

