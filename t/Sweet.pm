use strict;
use warnings;
use utf8;
use DBIx::Yakinny;

package t::Sweet;

{
    package MyApp::DB::Row::User;
    use base qw/DBIx::Yakinny::Row/;
    use Time::Piece;
    sub created_on_piece {
        Time::Piece->new($_[0]->created_on);
    }
}

{
    package TestSuite;
    use Test::More;
    use DBIx::Yakinny::Schema;

    sub run {
        my ($class, $dbh) = @_;

        my $schema = DBIx::Yakinny::Schema->new();
        $schema->register_table(
            class   => 'MyApp::DB::Row::User',
            table   => 'user',
            columns => [qw/user_id name email created_on/],
            primary_key      => 'user_id',
        );

        my $db = DBIx::Yakinny->new(
            dbh    => $dbh,
            schema => $schema,
        );

        subtest 'insert' => sub {
            $db->insert(user => {name => 'foo', email => 'foo@example.com'});
            is $db->last_insert_id, 1, 'insert,last_insert_id';
            $db->insert(user => {name => 'bar', email => 'bar@example.com'});
            is $db->last_insert_id, 2, 'insert,last_insert_id';
            $db->insert(user => {name => 'baz', email => 'baz@example.com'});
            is $db->last_insert_id, 3, 'insert,last_insert_id';
        };

        subtest 'single returns row' => sub {
            my $user = $db->single(user => {user_id => 2});
            ok $user;
            isa_ok $user, 'MyApp::DB::Row::User';
            is $user->name, 'bar';
            is $user->email, 'bar@example.com';
            is $user->user_id, 2;
        };

        subtest 'search returns array' => sub {
            my @users = $db->search(user => {name => {like => 'ba%'}}, {order_by => 'name'});
            is scalar(@users), 2;
            is $users[0]->name, 'bar';
            is $users[1]->name, 'baz';
        };

        subtest 'search returns iter' => sub {
            my $iter = $db->search(user => {name => {like => 'ba%'}}, {order_by => 'name'});
            my @names = qw/bar baz/;
            while (my $user = $iter->next) {
                my $expected = shift @names;
                is $user->name, $expected;
            }
            is scalar(@names), 0;
        };

        subtest 'find_or_create' => sub {
            {
                my $user = $db->find_or_create(user => {user_id => 4, name => 'john'});
                is $user->user_id, 4;
                is $user->name, 'john';
            }
            {
                my $user = $db->find_or_create(user => {user_id => 4, name => 'john'});
                is $user->user_id, 4;
                is $user->name, 'john';
            }
        };

        subtest 'retrieve' => sub {
            my $user = $db->retrieve(user => 3);
            is $user->name, 'baz';
            is $db->retrieve(user => 9999), undef;
        };

        subtest 'single returns undef' => sub {
            my $user = $db->single(user => {user_id => 99999});
            is $user, undef;
        };

        subtest 'search_by_sql' => sub {
            my ($u) = $db->search_by_sql(user => q{SELECT COUNT(*) AS cnt FROM user});
            is $u->get_column('cnt'), 4;
            is join(',', map { $_->name } $db->search_by_sql(user => q{SELECT * FROM user WHERE name LIKE 'ba%' ORDER BY name})), 'bar,baz';
        };

        subtest 'delete' => sub {
            {
                my $u = $db->single(user => {name => 'john'});
                $u->delete();
            }

            {
                my $u = $db->single(user => {name => 'john'});
                is $u, undef;
            }
        };

        subtest 'bulk_insert' => sub {
            $db->bulk_insert(user => [{name => 'u1'}, {name => 'u2'}]);
            my $u1 = $db->single(user => {name => 'u1'});
            is $u1->name, 'u1';
            my $u2 = $db->single(user => {name => 'u2'});
            is $u2->name, 'u2';
        };

        subtest 'refetch' => sub {
            my $u = $db->insert(user => {name => 'u9'});
            $u->update({email => 'u9@example.com'});
            is $u->email, undef;
            $u = $u->refetch();
            is $u->email, 'u9@example.com';
        };

        subtest 'update' => sub {
            {
                my $u = $db->single(user => {name => 'u1'});
                $u->update({name => 'u3'});
            }

            {
                my $u = $db->single(user => {name => 'u1'});
                is $u, undef;
            }

            {
                my $u = $db->single(user => {name => 'u3'});
                is $u->name, 'u3';
            }
        };
    }
}

1;

