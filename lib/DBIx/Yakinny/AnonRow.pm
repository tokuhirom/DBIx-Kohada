package DBIx::Yakinny::AnonRow;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    delete $attr{__yakinny}; # it's completely useless for anon row
    return bless {%attr}, $class;
}

sub columns {
    my $self = shift;
    grep !/^__/, keys %$self;
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
    Carp::croak("$name was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    +{ map { $_ => $self->{$_} } $self->columns() };
}

1;
