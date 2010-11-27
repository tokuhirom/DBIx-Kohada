package DBIx::Yakinny;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';
use Module::Load ();
use Class::Accessor::Lite;
use Carp ();
use Class::Load ();

use SQL::Builder;

use DBIx::Yakinny::Iterator;

Class::Accessor::Lite->mk_accessors(__PACKAGE__, qw/dbh query_builder/);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless {%args}, $class;
    $self->{query_builder} ||= SQL::Builder->new(dbh => $self->{dbh});
    return $self;
}

sub set_schema_class {
    my $class = shift;
    my $schema_class = shift;
    Class::Load::load_class($schema_class);
    no strict 'refs';
    *{"${class}::schema_class"} = sub { $schema_class };
}

sub single {
    my ($self, $table, $where,) = @_;

    my $row_class = $self->schema_class->get_class_for($table);
    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bind);
    my $row = $sth->fetchrow_hashref();
    $sth->finish;
    if ($row) {
        return $row_class->new(yakinny => $self, row => $row);
    } else {
        return undef;
    }
}

sub search  {
    my ($self, $table, $where, $opt) = @_;
    my $row_class = $self->schema_class->get_class_for($table);

    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where, $opt);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bind);
    if (wantarray) {
        my @ret;
        while (my $row = $sth->fetchrow_hashref()) {
            push @ret, $row_class->new(yakinny => $self, row => $row);
        }
        $sth->finish;
        return @ret;
    } else {
        return DBIx::Yakinny::Iterator->new(sth => $sth, table => $table, yakinny => $self);
    }
}

sub insert  {
    my ($self, $table, $values) = @_;

    my ($sql, @bind) = $self->query_builder->insert($table, $values);
    $self->dbh->do($sql, {}, @bind);
    if (defined wantarray) {
        my $current_last_insert_id = $self->last_insert_id;
        if ($current_last_insert_id) {
            return $self->retrieve($table => $current_last_insert_id);
        }

        # find row
        my $row_class = $self->schema_class->get_class_for($table);
        my $pk = $row_class->pk;
        my $criteria = {};
        for my $pk1 (@{$row_class->pk}) {
            $criteria->{$pk1} = $values->{$pk1};
        }
        return $self->single($table => $criteria);
    }
}

sub last_insert_id {
    my $self = shift;
    my $dbh  = $self->dbh;

    my $driver = $dbh->{Driver}->{Name};
    if ( $driver eq 'mysql' ) {
        return $dbh->{mysql_insertid};
    } elsif ( $driver eq 'Pg' ) {
        die 'todo';
    } elsif ( $driver eq 'SQLite' ) {
        return $dbh->func('last_insert_rowid');
    } else {
        Carp::croak "Don't know how to get last insert id for $driver";
    }
}

sub find_or_create {
    my ($self, $table, $values) = @_;
    my $row = $self->single($table, $values);
    return $row if $row;
    return $self->insert($table, $values);
}

sub retrieve {
    my ($self, $table, $vals) = @_;
    $vals = [$vals] unless ref $vals;
    my $row_class = $self->schema_class->get_class_for($table);

    my $criteria = {};
    for (my $i=0; $i<@{$row_class->pk}; $i++) {
        my $k = $row_class->pk->[$i];
        my $v = $vals->[$i];
        $criteria->{$k} = $v;
    }
    return $self->single($table => $criteria);
}

sub bulk_insert {
    my ($self, $table, $rows) = @_;
    my $driver = $self->dbh->{Driver}->{Name};
    if ($driver eq 'mysql') {
        my ($sql, @binds) = $self->query_builder->insert_multi($table, $rows);
        $self->dbh->do($sql, {}, @binds);
    } else {
        for my $row (@$rows) {
            # do not use $self->insert here for consistent behaivour
            my ($sql, @binds) = $self->query_builder->insert($table, $row);
            $self->dbh->do($sql, {}, @binds);
        }
    }
    return;
}

sub search_by_sql {
    my ($self, $table, $sql, @binds) = @_;
    my $row_class = $self->schema_class->get_class_for($table);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    if (wantarray) {
        my @ret;
        while (my $row = $sth->fetchrow_hashref()) {
            push @ret, $row_class->new(yakinny => $self, row => $row);
        }
        $sth->finish;
        return @ret;
    } else {
        return DBIx::Yakinny::Iterator->new(sth => $sth, table => $table, yakinny => $self);
    }
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Yakinny -

=head1 SYNOPSIS

    package MyApp::DB;
    use base qw/DBIx::Yakinny/;
    __PACKAGE__->schema_class('MyApp::DB::Schema');

    package MyApp::DB::Schema;
    use base qw/DBIx::Yakinny::Schema/;

    __PACKAGE__->register_table(
        class   => 'MyApp::DB::User',
        table   => 'user',
        columns => [qw/user_id name email/],
        pk      => 'user_id',
    );

    package MyApp::DB::User;
    use base qw/DBIx::Yakinny::Row/;

    package main;
    use MyApp::DB::Schema;
    use DBIx::Yakinny::Schema;
    use DBI;

    my $dbh = DBI->connect(...);
    my $db = MyApp::DB->new(dbh => $dbh);
    $db->dbh; # => #dbh
    my $user = $db->insert('user' => {name => 'john', email => 'john@exapmle.com'});
    say $user->name; # => john
    $user->name('mark');
    $user->update;
    $user->delete();

    my @users = $db->search_by_sql('user' => q{SELECT * FROM user WHERE name LIKE 'dai%'});

    my $user = $db->single('user' => {user_id => 3});
    my $iter = $db->search('user' => {user_id => 3});
    my @users = $db->search('user' => {user_id => 3});

=head1 DESCRIPTION

DBIx::Yakinny is

=head1 FAQ

=over 4

=item How do you use trigger like Class::DBI?

You should use trigger on RDBMS layer. It is reliable.

=item How do you use inflate/deflate?

This module does not support it.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
