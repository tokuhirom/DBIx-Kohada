use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Iterator;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/sth row_class kohada query/],
);

sub next {
    my $self = shift;
    if (my $row = $self->sth->fetchrow_hashref) {
        return $self->row_class->new(query => $self->query, kohada => $self->kohada, row_data => $row);
    } else {
        $self->sth->finish;
        return;
    }
}

sub all {
    my $self = shift;
    my @row;
    while (my $row = $self->next) {
        push @row, $row;
    }
    return @row;
}

sub rows { $_[0]->sth->rows }

1;
__END__

=head1 NAME

DBIx::Kohada::Iterator - Iterator Object for Kohada

=head1 SYNOPSIS

    while (my $row = $iter->next) {
        ...
    }

=head1 METHODS

=over 4

=item my $item = $iter->next()

Fetch one row from iterator. It returns undef when end of iteration.

=item my @items = $iter->all()

Fetch items at once.

=item my $rows = $iter->rows()

This is synonym for $iter->sth->rows

=back
