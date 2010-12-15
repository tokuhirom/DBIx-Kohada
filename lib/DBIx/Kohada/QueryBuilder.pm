use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::QueryBuilder;
use parent qw/SQL::Maker/;

__PACKAGE__->load_plugin($_)
    for qw/InsertMulti/;

1;
__END__

=head1 NAME

DBIx::Kohada::QueryBuilder - default query builder class

=head1 DESCRIPTION

This is a default query builder class for L<DBIx::Kohada>.
This class is a child class of  L<SQL::Maker>, and it loads L<SQL::Maker::Plugin::InsertMulti>.

=head1 SEE ALSO

L<SQL::Maker>, L<SQL::Maker::Plugin::InsertMulti>.

