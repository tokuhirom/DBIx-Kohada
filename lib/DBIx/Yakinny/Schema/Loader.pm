package DBIx::Yakinny::Schema::Loader;
use strict;
use warnings;
use utf8;
use DBIx::Inspector;
use DBIx::Yakinny::Util;
use DBIx::Yakinny::Schema;
use Carp ();

sub load {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $dbh = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
    my $schema_class = $args{schema_class} || DBIx::Yakinny::Util::create_anon_class(prefix => 'DBIx::Yakinny::AnonSchema');
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    no strict 'refs';
    @{"${schema_class}::ISA"} = qw/DBIx::Yakinny::Schema/;
    for my $table ($inspector->tables) {
        $schema_class->register_table(
            table   => $table->name,
            columns => [ map { $_->name } $table->columns ],
            pk      => [ map { $_->name } $table->primary_key ],
        );
    }
    return $schema_class;
}

1;
__END__

=head1 SYNOPSIS

    package MyApp::DB;
    use base qw/DBIx::Yakinny::Schema/;
    my $dbh = DBI->connect(...) or die;
    my $schema = DBIx::Yakinny::Schema::Loader->load( dbh => $dbh );
    my $db = DBIx::Yakinny->new(dbh => $dbh, schema => $schema);

