package DBIx::Yakinny::Plugin::Trigger;
use strict;
use warnings;
use utf8;
use Role::Tiny;

my %TRIGGERS;

around 'insert' => sub {
    my $orig = shift;
    my ($self, $table, $values, $opt) = @_;
    if (my $triggers = $TRIGGERS{ref $self}->{$table}->{before_insert}) {
        for my $trigger (@$triggers) {
            $trigger->($self, $values);
        }
    }
    if (my $triggers = $TRIGGERS{ref $self}->{$table}->{after_insert}) {
        my $row = $orig->(@_);
        for my $trigger (@$triggers) {
            $trigger->($self, $row);
        }
        return $row;
    } else {
        return $orig->(@_); # respect parent's context
    }
};

around 'update_row' => sub {
    my $orig = shift;
    my ($self, $row, $attr) = @_;
    if (my $triggers = $TRIGGERS{ref $self}->{$row->table}->{before_update}) {
        for my $trigger (@$triggers) {
            $trigger->($self, $row, $attr);
        }
    }
    $orig->(@_);
    if (my $triggers = $TRIGGERS{ref $self}->{$row->table}->{after_update}) {
        for my $trigger (@$triggers) {
            $trigger->($self, $row, $attr);
        }
    }
};

around 'delete_row' => sub {
    my $orig = shift;
    my ($self, $row, $attr) = @_;
    if (my $triggers = $TRIGGERS{ref $self}->{$row->table}->{before_delete}) {
        for my $trigger (@$triggers) {
            $trigger->($self, $row, $attr);
        }
    }
    $orig->(@_);
    if (my $triggers = $TRIGGERS{ref $self}->{$row->table}->{after_delete}) {
        for my $trigger (@$triggers) {
            $trigger->($self, $row, $attr);
        }
    }
};

sub add_trigger {
    my ($class, $table, $point, $code) = @_;
    push @{$TRIGGERS{$class}->{$table}->{$point}}, $code;
}

1;

