package DBIx::Yakinny::QueryBuilder;
use strict;
use warnings;
use utf8;
use parent qw/SQL::Builder/;

__PACKAGE__->load_plugin($_)
    for qw/InsertMulti Replace/;

1;

