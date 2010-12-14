use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::QueryBuilder;
use parent qw/SQL::Maker/;

__PACKAGE__->load_plugin($_)
    for qw/InsertMulti/;

1;

