package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
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
}

sub get_class_for {
    my ($class, $table) = @_;
    no strict 'refs';
    return ${"${class}::TABLES"}->{$table}->{class};
}

1;
