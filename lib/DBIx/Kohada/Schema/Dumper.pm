use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Schema::Dumper;
use DBIx::Inspector 0.03;
use Carp ();
use Data::Dumper ();

sub dump {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $callback = $args{table2class_cb} or Carp::croak("missing mandatory parameter 'table2class_cb'");
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my $ret = "do {\n";
    $ret .= "use DBIx::Kohada::Schema;\n";
    $ret .= "my \$schema = DBIx::Kohada::Schema->new();\n";
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    for my $table_info (sort { $_->name } $inspector->tables) {
        my $row_class = $callback->($table_info->name);
        $ret .= "{\n";
        $ret .= "eval { require ${row_class} } or do { unshift \@${row_class}::ISA, q{DBIx::Kohada::Row} };\n";
        $ret .= sprintf("${row_class}->set_table(q{%s});\n${row_class}->set_primary_key(qw/%s/);\n", $table_info->name, join(' ', map { $_->name } $table_info->primary_key));
        $ret .= sprintf("${row_class}->add_column(\$_) for (qw/%s/);\n", join(' ', map { $_->name } $table_info->columns));
        $ret .= "\$schema->register_row_class('${row_class}');\n";
        $ret .= "}\n";
    }
    $ret .= "\n\$schema;\n}\n";
    return $ret;
}

1;
__END__

=for test_synopsis
my (@dsn);

=head1 NAME

DBIx::Kohada::Schema::Dumper - Schema code generator

=head1 SYNOPSIS

    use DBI;
    use DBIx::Kohada::Schema::Dumper;

    my $dbh = DBI->connect(@dsn) or die;
    print DBIx::Kohada::Schema::Dumper->dump(dbh => $dbh, table2class_cb => sub {
        'MyApp::DB::Row::' . camelize($_[0]);
    });

=head1 DESCRIPTION

This module generates the Perl code to generate L<DBIx::Kohada::Schema> instance.

You can use it by C<do "my/schema.pl"> or embed it to the package.

B<THIS MODULE IS HIGHLY EXPERIMENTAL. DO NOT USE THIS FOR PRODUCTION ENVIRONMENT.>

=head1 METHODS

=over 4

=item DBIx::Kohada::Dumper->dump(dbh => $dbh, table2class_cb => \&code);

This is the method to generate code from DB. It returns the Perl5 code in string.

The arguments are:

=over 4

=item dbh

Database handle from DBI.

=item table2class_cb

Coderef to convert table name to row class name.

The method is calling with following form:

    my $class_name = $code->($table_name);


=back


=back

