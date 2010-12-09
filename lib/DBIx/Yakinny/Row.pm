package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use Carp ();
use DBIx::Yakinny;

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub add_column {
    my ($class, $name) = @_;
    no strict 'refs';
}

sub columns {
    my $self = shift;
    grep !/^__/, keys %$self;
}

sub primary_key { $_[0]->table->primary_key }

sub set_table {
    my ($class, $table) = @_;
    no strict 'refs';
    *{"${class}::table"} = sub { $table };
    for my $col ($table->columns) {
        *{"${class}::$col"} = sub { $_[0]->get_column($col) };
    }
}

sub get_column {
    my ($self, $name) = @_;
    return $self->{$name} if exists $self->{$name};
    Carp::croak("$name was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    return +{ map { $_ => $self->{$_} } $self->columns };
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
    my $y = $_[0]->{__yakinny};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Yakinny object in this instance(This situation is caused by Storable::freeze).");
    }
}

1;
