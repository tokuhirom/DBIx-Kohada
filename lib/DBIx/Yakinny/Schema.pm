package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Carp ();
use Class::Load;
use Class::Method::Modifiers;
use DBIx::Yakinny::Util;

sub register_table {
    my ($class, %attr) = @_;
    my $table = $attr{table};
    no strict 'refs';
    no warnings 'once';
    ${"${class}::TABLES"}->{$table} = \%attr;
    my $klass;
    if ($klass = $attr{class}) {
        Class::Load::load_class($klass);
        Carp::croak("$klass must inherit DBIx::Yakinny::Row") unless $klass->isa('DBIx::Yakinny::Row');
    } else {
        $klass = DBIx::Yakinny::Util::create_anon_class(
            prefix => "${class}::AnonRow",
            isa    => ['DBIx::Yakinny::Row']
        );
        $attr{class} = $klass;
    }
    $klass->add_column($_) for @{$attr{columns}};

    my $pk = $attr{pk};
    $pk = [$pk] unless ref $pk;
    $klass->set_pk($pk);

    $klass->set_table($table);

    return $klass; # created row class name
}

sub get_class_for {
    my ($class, $table) = @_;
    no strict 'refs';
    return ${"${class}::TABLES"}->{$table}->{class};
}

1;
