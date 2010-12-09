use strict;
use warnings;
use utf8;

package DBIx::Yakinny::Table;
use Class::Accessor::Lite (
    rw => [
        'name',         # Str
        'primary_key',  # ArrayRef[Str]
    ],
    ro => [
        'column_infos', # ArrayRef[HashRef]
    ],
);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless {
        column_infos => [],
        columns      => [],
        %args
    }, $class;
}

sub add_column {
    my ($self, $stuff) = @_;
    $stuff = +{ COLUMN_NAME => $stuff } unless ref $stuff;
    my $name = $stuff->{COLUMN_NAME} || Carp::croak "missing COLUMN_NAME";
    push @{$self->column_infos}, $stuff;
    push @{$self->columns}, $stuff->{COLUMN_NAME};
}

sub columns {
    my $self = shift;
    return wantarray ? @{$self->{columns}} : $self->{columns};
}

1;
