package DBIx::Yakinny::Schema::Dumper;
use strict;
use warnings;
use utf8;
use DBIx::Inspector 0.03;
use Carp ();
use Data::Dumper ();
use DBIx::Yakinny::Util ();

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $ret = "do {\n";
    $ret .= "use DBIx::Yakinny::Schema;\n";
    $ret .= "use DBIx::Yakinny::Util;\n";
    $ret .= "my \$schema = DBIx::Yakinny::Schema->new();\n";
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    for my $table ($inspector->tables) {
        $ret .= "{\n";
        $ret .= "my \$klass = DBIx::Yakinny::Util::create_anon_class(prefix => 'DBIx::Yakinny::AnonRow', isa => ['DBIx::Yakinny::Row']);\n"; # TODO: receive class map
        $ret .= sprintf("\$klass->set_table(q{%s});\n", $table->name);
        $ret .= sprintf("\$klass->add_column(\$_) for (\n");
        for my $column ($table->columns) {
        my $src = +{ map { $_ => $column->{$_}} qw/COLUMN_NAME DECIMAL_DIGITS COLUMN_DEF NUM_PREC_RADIX CHAR_OCTET_LENGTH REMARKS IS_NULLABLE COLUMN_SIZE ORDINAL_POSITION TYPE_NAME NULLABLE DATA_TYPE SQL_DATA_TYPE SQL_DATETIME_SUB/ };
        $ret .= sprintf("    %s,\n", Data::Dumper::Dumper($src));
        }
        $ret .= sprintf(");\n");
        $ret .= sprintf("\$klass->set_primary_key([qw(%s)]);\n", join(' ', map { $_->name } $table->primary_key));
        $ret .= "\$schema->register_table(\$klass);\n";
        $ret .= "}\n";
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

