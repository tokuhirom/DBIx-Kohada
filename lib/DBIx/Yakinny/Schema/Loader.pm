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
    my $schema = DBIx::Yakinny::Schema->new();
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    for my $table ($inspector->tables) {
        $schema->register_table(
            table   => $table->name,
            columns => [ map { $_->name } $table->columns ],
            primary_key      => [ map { $_->name } $table->primary_key ],
        );
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

