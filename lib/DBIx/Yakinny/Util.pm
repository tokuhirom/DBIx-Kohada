package DBIx::Yakinny::Util;
use strict;
use warnings;
use utf8;
use DBIx::Yakinny::Row;

{
    my $i = 0;
    sub create_anon_class {
        my %args = @_;
        my $klass = $args{prefix} . '::' . $i++;
        if (my $isa = $args{isa}) {
            no strict 'refs';
            @{"${klass}::ISA"} = @$isa;
        }
        return $klass;
    }
}

1;

