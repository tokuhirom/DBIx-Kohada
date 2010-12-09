package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my $class = shift;
    bless {'table2row_class' => +{}}, $class;
}

sub table2row_class {
    my ($self, $table) = @_;
    return $self->{table2row_class}->{$table};
}

sub tables {
    my $self = shift;
    return map { $_->table } values %{$self->{table2row_class}};
}

sub register_row_class {
    my ($self, $row_class) = @_;

    Carp::croak("$row_class must inherit DBIx::Yakinny::Row") unless $row_class->isa('DBIx::Yakinny::Row');

    $self->{table2row_class}->{$row_class->table->name} = $row_class;
}

1;
