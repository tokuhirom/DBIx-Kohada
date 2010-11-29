package DBIx::Yakinny::Schema::Object;
use strict;
use warnings;
use utf8;
use parent qw/DBIx::Yakinny::Schema/;

sub new {
    my $class = shift;
    bless {'map' => +{}}, $class;
}

sub set_class_table {
    my ($class, $table, $row) = @_;
    $class->{map}->{$table} = $row;
}

sub get_class_for {
    my ($class, $table) = @_;
    return $class->{map}->{$table};
}

1;

