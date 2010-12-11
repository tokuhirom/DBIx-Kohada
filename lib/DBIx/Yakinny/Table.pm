use strict;
use warnings FATAL => 'all';
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
    my $columns = delete $args{columns};
    my $self = bless {
        column_infos => [],
        columns      => [],
        primary_key  => [],
        %args
    }, $class;
    if ($columns) {
        $self->add_column($_) for @$columns;
    }
    return $self;
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
