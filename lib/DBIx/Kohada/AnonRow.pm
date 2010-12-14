use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::AnonRow;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%{$attr{row_data}}}, $class;
}

sub columns {
    my $self = shift;
    keys %$self;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $proto = ref $self || $self;
    (my $column = $AUTOLOAD) =~ s/$proto\:://;
    return $self->get_column($column);
}
sub DESTROY { 1 } # dummy for AUTOLOAD.

sub get_column {
    my ($self, $name) = @_;
    return $self->{$name} if exists $self->{$name};
    Carp::croak("'$name' was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    +{ map { $_ => $self->{$_} } $self->columns() };
}

1;
