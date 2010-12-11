use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Yakinny::Schema;
use Carp ();

sub new {
    my $class = shift;
    bless {'table_name2row_class' => +{}}, $class;
}

sub table_name2row_class {
    my ($self, $table) = @_;
    return $self->{table_name2row_class}->{$table};
}

sub table_name2table {
    my ($self, $table) = @_;
    return $self->{table_name2table}->{$table};
}

sub row_class2table{
    my ($self, $row_class) = @_;
    return $self->{row_class2table}->{$row_class};
}

sub tables {
    my $self = shift;
    return values %{$self->{table_name2table}};
}

sub register_table {
    my ($self, $table, $row_class) = @_;
    Carp::croak(__PACKAGE__ . "->register_table(\$table, \$row_class);") unless @_==3;
    Carp::confess("\$table should be object") unless ref $table;
    Carp::confess("The table @{[ $table->name ]} does not contain any column") unless @{$table->columns};

    $row_class->add_column_accessors($table->columns);

    $self->{table_name2row_class}->{$table->name}  = $row_class;
    $self->{table_name2table}->{$table->name} = $table;
    $self->{row_class2table}->{$row_class} = $table;
}

1;
