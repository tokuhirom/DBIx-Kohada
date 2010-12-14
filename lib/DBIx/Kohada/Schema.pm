use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Schema;
use Carp ();

sub new {
    my $class = shift;
    bless {'table_name2row_class' => +{}}, $class;
}

sub table_name2row_class {
    my ($self, $table) = @_;
    return $self->{table_name2row_class}->{$table};
}

sub table_names {
    my $self = shift;
    return keys %{$self->{table_name2row_class}};
}

sub register_row_class {
    my ($self, $row_class) = @_;
    Carp::croak(__PACKAGE__ . "->register_row_class(\$row_class);") unless @_==2;

    $self->{table_name2row_class}->{$row_class->table}  = $row_class;
}

1;
