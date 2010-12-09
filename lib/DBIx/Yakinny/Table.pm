use strict;
use warnings;
use utf8;

package DBIx::Yakinny::Table;
use Class::Accessor::Lite (
    ro => [
        'name',         # Str
        'primary_key',  # ArrayRef[Str]
        'column_infos', # ArrayRef[HashRef]
    ],
);

sub columns {
    my $self = shift;
    return wantarray ? @{$self->{columns}} : $self->{columns};
}

sub new {
    my $class = shift;
    my %args = @_==1?%{$_[0]}:@_;
    bless {column_infos => [], columns => [], %args}, $class;
}

sub add_column {
    my ($self, $stuff) = @_;
    $stuff = +{ COLUMN_NAME => $stuff } unless ref $stuff;
    my $name = $stuff->{COLUMN_NAME} || Carp::croak "missing COLUMN_NAME";
    push @{$self->column_infos}, $stuff;
    push @{$self->columns}, $stuff->{COLUMN_NAME};
}

1;
