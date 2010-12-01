package DBIx::Yakinny::Schema::Dumper;
use strict;
use warnings;
use utf8;
use DBIx::Inspector 0.03;
use Carp ();
use Data::Dumper ();

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $ret = "do {\n";
    $ret .= "use DBIx::Yakinny::Schema;\n";
    $ret .= "my \$schema = DBIx::Yakinny::Schema->new();\n";
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    for my $table ($inspector->tables) {
        $ret .= "\$schema->register_table(\n";
        $ret .= sprintf("  table => q{%s},\n", $table->name);
        $ret .= sprintf("  columns => [\n");
        for my $column ($table->columns) {
        my $src = +{ map { $_ => $column->{$_}} qw/COLUMN_NAME DECIMAL_DIGITS COLUMN_DEF NUM_PREC_RADIX CHAR_OCTET_LENGTH REMARKS IS_NULLABLE COLUMN_SIZE ORDINAL_POSITION TYPE_NAME NULLABLE DATA_TYPE SQL_DATA_TYPE SQL_DATETIME_SUB/ };
        $ret .= sprintf("    %s,\n", Data::Dumper::Dumper($src));
        }
        $ret .= sprintf("],\n");
        $ret .= sprintf("  primary_key      => [qw(%s)],\n", join(' ', map { $_->name } $table->primary_key));
        $ret .= ");\n\n";
    }
    $ret .= "\n\$schema;\n}\n";
    return $ret;
}

1;
__END__

=head1 SYNOPSIS

    use DBI;
    use DBIx::Yakinny::Schema::Dumper;

    my $dbh = DBI->connect(...) or die;
    print DBIx::Yakinny::Schema::Dumper->dump(dbh => $dbh);

