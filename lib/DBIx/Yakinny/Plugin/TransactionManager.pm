package DBIx::Yakinny::Plugin::TransactionManager;
use strict;
use warnings;
use utf8;
use Role::Tiny;
use DBIx::TransactionManager;

sub transaction_manager {
    my $self = shift;
    $self->{transaction_manager} ||= DBIx::TransactionManager->new($self->dbh);
}

sub txn_scope {
    my $self = shift;
    return $self->transaction_manager->txn_scope();
}

1;
