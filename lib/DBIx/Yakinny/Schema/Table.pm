package DBIx::Yakinny::Schema::Table;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/name columns primary_key/],
);

sub add_column {
    my ($self, $stuff) = @_;
    $stuff = +{ COLUMN_NAME => $stuff } unless ref $stuff;
    push @{$self->{columns}}, $stuff;
}

sub column_names {
    my ($self) = @_;
    map { $_->{COLUMN_NAME} } @{$self->columns};
}

1;

