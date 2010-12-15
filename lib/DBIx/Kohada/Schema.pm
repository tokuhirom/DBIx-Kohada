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
    my @ret = keys %{$self->{table_name2row_class}};
    return wantarray ? @ret : \@ret;
}

sub register_row_class {
    my ($self, $row_class) = @_;
    Carp::croak(__PACKAGE__ . "->register_row_class(\$row_class);") unless @_==2;

    $self->{table_name2row_class}->{$row_class->table}  = $row_class;
}

1;
__END__

=for test_synopsis
my ($dbh);

=head1 NAME

DBIx::Kohada::Schema - DB Schema

=head1 SYNOPSIS

    my $schema = DBIx::Kohada::Schema->new();
    $schema->register_row_class('MyApp::DB::Row::User');
    my $kohada = DBIx::Kohada->new(schema => $schema, dbh => $dbh);

=head1 DESCRIPTION

This is a schema class for L<DBIx::Kohada>. You register the row class to schema before use it.

=head1 METHODS

=over 4

=item my $schema = DBIx::Kohada::Schema->new();

Create new schema instance.

=item $schema->register_row_class($row_class : Str);

Register the $row_class to schema.

=item $schema->table_names()

Get the registered table names.

=item $schema->table_name2row_class($table_name : Str);

Get the row class name for $table_name. This method returns undef when it is not registered.

=back

