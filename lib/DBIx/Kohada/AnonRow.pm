use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::AnonRow;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%{$attr{row_data}}}, $class;
}

sub columns {
    my $self = shift;
    my @columns = keys %$self;
    return wantarray ? @columns : \@columns;
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
    Carp::croak("'$name' was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    +{ map { $_ => $self->{$_} } $self->columns() };
}

1;
__END__

=head1 NAME

DBIx::Kohada::AnonRow - Anonymous Row Object

=head1 DESCRIPTION

This object is an anonymous row object. It's instance is created by C<$db->search_by_sql(undef, $sql, @binds)> or C<$db->search_by_query_object($query)> method.

This class defines B<AUTOLOAD> method. If you calls missing method, then you get the column data on the method name.

    $row->foo();
    # is equivalent to
    $row->get_column('foo');

=head1 METHODS

=over 4

=item my $row = DBIx::Kohada::AnonRow->new(%args);

Create new instance of DBIx::Kohada::AnonRow. The arguments are:

=over 4

=item \%row_data

It contains fetched data in hashref.

=back

=item my @columns = $row->columns();

=item my $columns = $row->columns(); # ArrayRef in scalar context.

This method returns the fetched column names.

This method looks context by wantarray.

=item my $val = $row->get_column($column_name);

Return: The value of column.

Get the column data from row.

This method throws exception if the $column_name is not exists in the fetched data.

=item my $data = $row->get_columns();

Returns all loaded column data as a hash, containing raw values. To get
just one value for a particular column, use "get_column".

Returns: A hashref of column name, value pairs.

=back
