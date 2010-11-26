package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use base qw/Class::Data::Inheritable/;
use Class::Accessor::Lite;

sub add_column {
    my ($class, $name) = @_;
    Class::Accessor::Lite->mk_accessors($class => $name);
}

sub set_pk {
    my ($class, $name) = @_;
    no strict 'refs';
    *{"${class}::pk"} = sub { $name };
}

1;
