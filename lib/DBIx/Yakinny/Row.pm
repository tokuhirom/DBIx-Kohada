package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use DBIx::Yakinny;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub columns {
    my $self = shift;
    keys %{$self->{row_data}};
}

sub add_column_accessors {
    my $class = shift;
    no strict 'refs';
    for my $name (@_) {
        *{"${class}::$name"} = sub {
            return $_[0]->{row_data}->{$name} if exists $_[0]->{row_data}->{$name};
            Carp::croak("$name was not fetched by query.");
        };
    }
}

sub table { $_[0]->yakinny->schema->row_class2table(ref $_[0]) }

sub primary_key { $_[0]->table->primary_key }

sub set_table {
    my ($class, $table) = @_;
    no strict 'refs';
    for my $col ($table->columns) {
        *{"${class}::$col"} = sub { $_[0]->get_column($col) };
    }
}

sub get_column {
    my ($self, $name) = @_;
    return $self->{row_data}->{$name} if exists $self->{row_data}->{$name};
    Carp::croak("$name was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    return +{ map { $_ => $self->{row_data}->{$_} } $self->columns };
}

sub where_cond {
    my ($self) = @_;
    my @pk = @{$self->primary_key};
    Carp::confess("You cannot call this method whithout primary key") unless @pk;
    return +{ map { $_ => $self->get_column($_) } @pk };
}

sub update {
    my ($self, $attr) = @_;
    $self->yakinny->update_row($self, $attr);
    return;
}

sub delete {
    my $self = shift;
    $self->yakinny->delete_row($self);
    return;
}

sub refetch {
    my $self = shift;
    return $self->yakinny->single( $self->table->name => $self->where_cond );
}

sub yakinny {
    Carp::confess($_[0] . "->yakinny is a instance method.") unless ref $_[0];

    my $y = $_[0]->{__yakinny};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Yakinny object in this instance(This situation is caused by Storable::freeze).");
    }
}

1;
