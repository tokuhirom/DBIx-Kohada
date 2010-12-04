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
    package MyApp::DB::Row::Good;
    use base qw/DBIx::Yakinny::Row/;
    package MyApp::DB::Row::Entry;
    use base qw/DBIx::Yakinny::Row/;
}

{
    package TestSuite;
    use Test::More;
    use DBIx::Yakinny::Schema;

    my $schema;

    sub make_schema {
        $schema ||= do {
            my $s = DBIx::Yakinny::Schema->new();

            MyApp::DB::Row::User->set_table('user');
            MyApp::DB::Row::User->add_column($_) for qw/user_id name email created_on/;
            MyApp::DB::Row::User->set_primary_key(['user_id']);
            $s->register_table( 'MyApp::DB::Row::User' );

            MyApp::DB::Row::Entry->set_table('entry');
            MyApp::DB::Row::Entry->add_column($_) for qw/entry_id user_id body/;
            MyApp::DB::Row::Entry->set_primary_key(['entry_id']);
            $s->register_table( 'MyApp::DB::Row::Entry' );

            MyApp::DB::Row::Good->set_table('good');
            MyApp::DB::Row::Good->add_column($_) for qw/user_id entry_id/;
            MyApp::DB::Row::Good->set_primary_key(['user_id', 'entry_id']);
            $s->register_table( 'MyApp::DB::Row::Good' );

            $s;
        };
    }

    sub run {
        my ($class, $dbh) = @_;

        my $db = DBIx::Yakinny->new(
            dbh    => $dbh,
            schema => $class->make_schema(),
        );

        subtest 'tables' => sub {
            is join(',', sort $db->schema->tables), 'entry,good,user';
        };

        subtest 'insert' => sub {
            $db->insert(user => {name => 'foo', email => 'foo@example.com'});
            is $db->last_insert_id('user'), 1, 'insert,last_insert_id';
            $db->insert(user => {name => 'bar', email => 'bar@example.com'});
            is $db->last_insert_id('user'), 2, 'insert,last_insert_id';
            $db->insert(user => {name => 'baz', email => 'baz@example.com'});
            is $db->last_insert_id('user'), 3, 'insert,last_insert_id';

            my $entry = $db->insert(entry => {user_id => 1, body => 'yay!'});
            is $db->last_insert_id('entry'), 1, 'insert,last_insert_id';
            isa_ok $entry, 'MyApp::DB::Row::Entry';
            is $entry->body, 'yay!';

            my $good = $db->insert(good => {user_id => 32, entry_id => 1});
            isa_ok $good, 'MyApp::DB::Row::Good';
            is $good->user_id, 32;
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
            my $table = $db->dbh->quote_identifier('user');
            my ($u) = $db->search_by_sql(user => qq{SELECT COUNT(*) AS cnt FROM $table});
            is $u->get_column('cnt'), 4;
            is join(',', map { $_->name } $db->search_by_sql(user => qq{SELECT * FROM $table WHERE name LIKE 'ba%' ORDER BY name})), 'bar,baz';
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

        subtest 'update_row' => sub {
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

        subtest 'update' => sub {
            {
                my $u = $db->single(user => {name => 'u3'});
                ok $u;
                my $b = $db->single(user => {name => 'bee'});
                ok !$b;
            }
            $db->update('user' => {name => 'bee'}, {name => 'u3'});
            {
                my $u = $db->single(user => {name => 'u3'});
                ok !$u;
                my $b = $db->single(user => {name => 'bee'});
                ok $b;
            }
        };

        subtest 'delete' => sub {
            {
                my $b = $db->single(user => {name => 'bee'});
                ok $b;
            }
            $db->delete('user' => {name => 'bee'});
            {
                my $b = $db->single(user => {name => 'bee'});
                ok !$b;
            }
        };
    }
}

1;

