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
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $ret = "do {\n";
    $ret .= "use DBIx::Yakinny::Schema;\n";
    $ret .= "my \$schema = DBIx::Yakinny::Schema->new();\n";
    for my $table ($inspector->tables) {
        $ret .= "\$schema->register_table(\n";
        $ret .= sprintf("  table => q{%s},\n", $table->name);
        $ret .= sprintf("  columns => [qw(%s)],\n", join(' ', map { $_->name } $table->columns));
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

