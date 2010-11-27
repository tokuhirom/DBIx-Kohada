package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use base qw/Class::Data::Inheritable/;

Class::Accessor::Lite->mk_accessors(qw/yakinny/);

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub add_column {
    my ($class, $name) = @_;
    no strict 'refs';
    *{"${class}::$name"} = sub { $_[0]->get_column($name) };
    push @{"${class}::COLUMNS"}, $name;
}

sub columns {
    my $class = shift;
    no strict 'refs';
    @{"${class}::COLUMNS"};
}

sub set_pk {
    my ($class, $name) = @_;
    no strict 'refs';
    *{"${class}::pk"} = sub { $name };
}

sub set_table {
    my ($class, $table) = @_;
    no strict 'refs';
    *{"${class}::table"} = sub { $table };
}

sub get_column {
    my ($self, $name) = @_;
    $self->{row}->{$name};
}

sub where_cond {
    my ($self) = @_;
    +{ map { $_ => $self->get_column($_) } @{ $self->pk } }
}

sub update {
    my ($self, $attr) = @_;
    my ($sql, @binds) = $self->yakinny->abstract->update($self->table, $attr, $self->where_cond);
    $self->yakinny->dbh->do($sql, {}, @binds) == 1 or die;
}

sub delete {
    my $self = shift;
    my ($sql, @binds) = $self->yakinny->abstract->delete($self->table, $self->where_cond);
    $self->yakinny->dbh->do($sql, {}, @binds) == 1 or die;
}

1;
