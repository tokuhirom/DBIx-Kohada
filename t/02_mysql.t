use strict;
use warnings;
use Test::More;
use Test::Requires 'DBD::mysql', 'Test::mysqld';
use t::Sweet;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',    # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

my $dbh = DBI->connect( $mysqld->dsn( dbname => 'test' ), );
$dbh->do(q{
    create table user (
        user_id int primary key auto_increment,
        name varchar(255),
        email varchar(255),
        created_on int
    );
});
$dbh->do(q{
    create table entry (
        entry_id int primary key auto_increment,
        user_id int not null,
        body    text
    );
});
$dbh->do(q{
    create table good (
        entry_id integer,
        user_id  integer not null,
        PRIMARY KEY (entry_id, user_id)
    );
});
TestSuite->run($dbh);

done_testing;

