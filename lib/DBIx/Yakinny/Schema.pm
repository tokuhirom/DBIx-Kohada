package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Module::Load ();

sub register_table {
    my ($class, %attr) = @_;
    my $table = $attr{table};
    no strict 'refs';
    ${"${class}::TABLES"}->{$table} = \%attr;
    my $klass = Module::Load::load($attr{class});
    $klass->add_column($_) for @{$attr{columns}};

    my $pk = $attr{pk};
    $pk = [$pk] unless ref $pk;
    $klass->set_pk($pk);
}

sub get_class_for {
    my ($class, $table) = @_;
    no strict 'refs';
    return ${"${class}::TABLES"}->{$table}->{class};
}

1;
