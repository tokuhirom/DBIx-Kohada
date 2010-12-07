package DBIx::Yakinny::Schema::Loader;
use strict;
use warnings;
use utf8;
use DBIx::Inspector;
use DBIx::Yakinny::Schema;
use DBIx::Yakinny::Schema::Table;
use DBIx::Yakinny::Row;
use Carp ();

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $callback = $args{table2class_cb} or Carp::croak("missing mandatory parameter 'table2class_cb'");
    my $schema = DBIx::Yakinny::Schema->new();
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    for my $table_info ($inspector->tables) {
        my $row_class = $callback->($table_info->name);
        my $table = DBIx::Yakinny::Schema::Table->new(
            name => $table_info->name,
            columns => [ map { my $column = $_; +{ map { $_ => $column->{$_}} qw/COLUMN_NAME DECIMAL_DIGITS COLUMN_DEF NUM_PREC_RADIX CHAR_OCTET_LENGTH REMARKS IS_NULLABLE COLUMN_SIZE ORDINAL_POSITION TYPE_NAME NULLABLE DATA_TYPE SQL_DATA_TYPE SQL_DATETIME_SUB/ } } $table_info->columns ],
            primary_key => [map { $_->name } $table_info->primary_key],
        );
        $schema->map_table($table => $row_class);
    }
    return $schema;
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::DB;
    use base qw/DBIx::Yakinny::Schema/;
    my $dbh = DBI->connect(...) or die;
    my $schema = DBIx::Yakinny::Schema::Loader->load( dbh => $dbh );
    my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);

