use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Schema::Loader;
use DBIx::Inspector;
use DBIx::Kohada::Schema;
use DBIx::Kohada::Row;
use Carp ();

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $callback = $args{table2class_cb} or Carp::croak("missing mandatory parameter 'table2class_cb'");
    my $schema = DBIx::Kohada::Schema->new();
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    for my $table_info ($inspector->tables) {
        my $row_class = $callback->($table_info->name);
        unless ($row_class->isa('DBIx::Kohada::Row')) {
            no strict 'refs';
            unshift @{"${row_class}::ISA"}, 'DBIx::Kohada::Row'
        }
        $row_class->set_table($table_info->name);
        $row_class->set_primary_key(map { $_->name } $table_info->primary_key);
        $row_class->add_column( $_->name ) for $table_info->columns;
        $schema->register_row_class($row_class);
    }
    return $schema;
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/DBIx::Kohada::Schema/;
    my $dbh = DBI->connect(...) or die;
    my $schema = DBIx::Kohada::Schema::Loader->load( dbh => $dbh );
    my $db = DBIx::Kohada->new(dbh => $dbh, schema => $schema);

