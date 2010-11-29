package DBIx::Yakinny::Schema::Dumper;
use strict;
use warnings;
use utf8;
use DBIx::Inspector;
use Carp ();

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $schema_class = $args{schema_class} or Carp::croak "missing mandatory parameter 'schema_class'";
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $ret = "package $schema_class;\n";
    $ret .= "use strict;\n";
    $ret .= "use warnings;\n";
    $ret .= "use utf8;\n";
    $ret .= "use parent qw(DBIx::Yakinny::Schema);\n\n";
    for my $table ($inspector->tables) {
        $ret .= "__PACKAGE__->register_table(\n";
        $ret .= sprintf("  table => q{%s},\n", $table->name);
        $ret .= sprintf("  columns => [qw(%s)],\n", join(' ', map { $_->name } $table->columns));
        $ret .= sprintf("  primary_key      => [qw(%s)],\n", join(' ', map { $_->name } $table->primary_key));
        $ret .= ");\n\n";
    }
    $ret .= "\n1;\n";
    return $ret;
}

1;
__END__

=head1 SYNOPSIS

    use DBI;
    use DBIx::Yakinny::Schema::Dumper;

    my $dbh = DBI->connect(...) or die;
    print DBIx::Yakinny::Schema::Dumper->dump(dbh => $dbh, schema_class => 'DBIx::Yakinny::Schema');

