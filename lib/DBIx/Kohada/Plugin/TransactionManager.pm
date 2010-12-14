use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Plugin::TransactionManager;
use DBIx::TransactionManager;

our @EXPORT = qw/transaction_manager txn_scope/;

sub transaction_manager {
    my $self = shift;
    $self->{transaction_manager} ||= DBIx::TransactionManager->new($self->dbh);
}

sub txn_scope {
    my $self = shift;
    return $self->transaction_manager->txn_scope();
}

1;
