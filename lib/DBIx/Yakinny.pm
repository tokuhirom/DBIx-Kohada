package DBIx::Yakinny;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';
use Class::Accessor::Lite (
    ro => [qw/dbh/], # because if it change this attribute, then it breaks TransactionManger's state.
    rw => [qw/query_builder schema name_sep quote_char/],
);
use Carp ();

use DBIx::Yakinny::Iterator;
use DBIx::Yakinny::AnonRow;
use DBIx::Yakinny::QueryBuilder;
use Module::Load ();
require Role::Tiny;

our $FATAL;

$Carp::Internal{ (__PACKAGE__) }++;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    for (qw/schema dbh/) {
        Carp::croak("missing mandatory parameter: $_") unless $args{$_};
    }
    my $self = bless {%args}, $class;
    $self->{quote_char} = $self->dbh->get_info(29) || q{"};
    $self->{name_sep}   = $self->dbh->get_info(41) || q{.};
    $self->{query_builder} ||= DBIx::Yakinny::QueryBuilder->new(
        driver     => $self->dbh->{Driver}->{Name},
        quote_char => $self->quote_char,
        name_sep   => $self->name_sep,
    );
    return $self;
}

sub new_iterator {
    my ($self, @args) = @_;
    return DBIx::Yakinny::Iterator->new(@args, yakinny => $self);
}

sub load_plugin {
    my ($class, $name) = @_;
    $name = $name =~ s/^\+// ? $name : "DBIx::Yakinny::Plugin::$name";
    Module::Load::load($name);
    Role::Tiny->apply_role_to_package($class, $name);
}

sub single {
    my ($self, $table, $where,) = @_;

    $self->search($table, $where, {limit => 1})->next;
}

sub search  {
    my ($self, $table, $where, $opt) = @_;
    my $row_class = $self->schema->get_class_for($table) or Carp::croak "Unknown table : $table";

    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where, $opt);
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@bind) or Carp::croak $self->dbh->errstr;
    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class);
    return wantarray ? $iter->all : $iter;
}

sub search_by_sql {
    my ($self, $table, $sql, @binds) = @_;

    my $row_class;
    if ($table) {
        $row_class = $self->schema->get_class_for($table);
    }
    $row_class ||= 'DBIx::Yakinny::AnonRow';
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;
    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class, query => $sql);
    return wantarray ? $iter->all : $iter;
}

sub insert  {
    my ($self, $table, $values, $opt) = @_;
    return $self->_insert_or_replace($table, $values, $opt);
}

sub replace  {
    my ($self, $table, $values, $opt) = @_;
    return $self->_insert_or_replace($table, $values, +{%{$opt || +{}}, prefix => 'REPLACE'});
}

sub _insert_or_replace {
    my ($self, $table, $values, $opt) = @_;

    my ($sql, @bind) = $self->query_builder->insert($table, $values, $opt);
    $self->dbh->do($sql, {}, @bind) or Carp::croak $self->dbh->errstr;
    if (defined wantarray) {
        # find row
        my $row_class = $self->schema->get_class_for($table) or die "'$table' is not defined in schema";
        my $primary_key = $row_class->primary_key;
        if (@$primary_key == 1 && not exists $values->{$primary_key->[0]}) {
            return $self->retrieve($table => $self->last_insert_id($table));
        }

        my $criteria = {};
        for my $primary_key1 (@{$row_class->primary_key}) {
            $criteria->{$primary_key1} = $values->{$primary_key1};
        }
        return $self->single($table => $criteria);
    }
}

sub last_insert_id {
    my ($self, $table) = @_;

    # Note: DBD::Pg required $table name to get last_insert_id.
    return $self->dbh->last_insert_id("","",$table,"");
}

sub retrieve {
    my ($self, $table, $vals) = @_;
    $vals = [$vals] unless ref $vals;
    my $row_class = $self->schema->get_class_for($table);

    my $criteria = {};
    for (my $i=0; $i<@{$row_class->primary_key}; $i++) {
        my $k = $row_class->primary_key->[$i];
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
        $self->dbh->do($sql, {}, @binds) or Carp::croak $self->dbh->errstr;
    } else {
        for my $row (@$rows) {
            # do not use $self->insert here for consistent behaivour
            my ($sql, @binds) = $self->query_builder->insert($table, $row);
            $self->dbh->do($sql, {}, @binds) or Carp::croak $self->dbh->errstr;
        }
    }
    return;
}

sub delete_row {
    my ($self, $row) = @_;

    my ($sql, @binds) = $self->query_builder->delete($row->table, $row->where_cond);
    $self->dbh->do($sql, {}, @binds) == 1 or die "FATAL";
}

sub update_row {
    my ($self, $row, $attr) = @_;

    my ($sql, @binds) = $self->query_builder->update($row->table, $attr, $row->where_cond);
    $self->dbh->do($sql, {}, @binds) == 1 or die "FATAL";
}

sub delete {
    my ($self, $table, $where) = @_;
    my ($sql, @binds) = $self->query_builder->delete($table, $where);
    $self->dbh->do($sql, {}, @binds);
}

sub update {
    my ($self, $table, $attr, $where) = @_;
    my ($sql, @binds) = $self->query_builder->update($table, $attr, $where);
    $self->dbh->do($sql, {}, @binds);
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Yakinny -

=head1 SYNOPSIS

    package MyApp::DB::Row::User;
    use base qw/DBIx::Yakinny::Row/;
    __PACKAGE__->set_table('user');
    __PACKAGE__->set_primary_key('user_id');
    __PACKAGE__->add_column($_) for qw/user_id name email/;

    package main;
    use DBIx::Yakinny::Schema;
    use DBIx::Yakinny;
    use DBI;

    my $schema = DBIx::Yakinny::Schema->new();
    $schema->register_table('MyApp::DB::Row::User');

    my $dbh = DBI->connect(...);
    my $db = DBIx::Yakinny->new(
        dbh    => $dbh,
        schema => $schema,
    );
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

DBIx::Yakinny is yet another O/R mapper based on Active Record strategy.

=head1 FAQ

=over 4

=item How do you use trigger like Class::DBI?

You should use trigger on RDBMS layer. It is reliable.

But, you can use the trigger with L<DBIx::Yakinny::Plugin::Trigger>.

=item How do you use inflate/deflate?

This module does not support it. But, you can use it by method modifier with L<Class::Method::Modifiers>.

=item How do you use tracer like DBIx::Skinny::Profiler::Trace?

You can use tracer by DBI. And you can use the advanced tracer like this article: L<http://d.hatena.ne.jp/tokuhirom/20101201/1291196584>.

=item How do you use relationships?

It is not supported in core. You can write a plugin to do it.

=item How do you handle reconnect?

use L<DBIx::Connector>.

=item How do you use nested transaction?

use L<DBIx::Yakinny::Plugin::TransactionManager>.

=item How do you use on_connect_do like DBIC?

use $dbh->{Callbacks}->{connected}.

=item How do you use display the profiling result like L<DBIx::Skinny::Profiler>?

use L<Devel::KYTProf>.

=item How do you display pretty error message?

use DBI's callback functions. fore modetails, see eg/dbi-callback.pl.

=item How do you load child classes automatically?

use L<Module::Find>.

    use Module::Find;
    my $schema = DBIx::Yakinny::Schema->new();
    $schema->register_table($_) for useall "MyApp::DB::Row";

=item How do you handle utf8 columns?

You should use B<mysql_enable_utf8>, B<sqlite_unicode>, etc.

=item Why don't you implement 'find_or_create' method?

It is not atomic operation.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
