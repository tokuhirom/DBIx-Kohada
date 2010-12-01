package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Carp ();
use Class::Load;
use Class::Method::Modifiers;
use DBIx::Yakinny::Util;

sub new {
    my $class = shift;
    bless {'map' => +{}}, $class;
}

sub get_class_for {
    my ($self, $table) = @_;
    return $self->{map}->{$table};
}

sub register_table {
    my ($self, %attr) = @_;
    my $table = $attr{table};
    my $klass;
    if ($klass = $attr{class}) {
        Class::Load::load_class($klass);
        Carp::croak("$klass must inherit DBIx::Yakinny::Row") unless $klass->isa('DBIx::Yakinny::Row');
    } else {
        my $class = ref $self;
        $klass = DBIx::Yakinny::Util::create_anon_class(
            prefix => "${class}::AnonRow",
            isa    => ['DBIx::Yakinny::Row']
        );
    }

    $self->{map}->{$table} = $klass;

    $klass->add_column($_) for @{$attr{columns}};

    my $primary_key = $attr{primary_key};
    $primary_key = [$primary_key] unless ref $primary_key;
    $klass->set_primary_key($primary_key);

    $klass->set_table($table);

    return $klass; # created row class name
}

1;
