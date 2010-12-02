package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my $class = shift;
    bless {'map' => +{}}, $class;
}

sub get_class_for {
    my ($self, $table) = @_;
    return $self->{map}->{$table};
}

# TODO: add 'tables' method?

sub register_table {
    my ($self, $klass) = @_;

    Carp::croak("$klass must inherit DBIx::Yakinny::Row") unless $klass->isa('DBIx::Yakinny::Row');

    $self->{map}->{$klass->table} = $klass;
}

1;
