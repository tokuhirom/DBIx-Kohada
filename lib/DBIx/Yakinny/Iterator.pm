package DBIx::Yakinny::Iterator;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    ro => [qw/sth row_class yakinny query/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next {
    my $self = shift;
    if (my $row = $self->sth->fetchrow_hashref) {
        return $self->row_class->new(__query => $self->query, __yakinny => $self->yakinny, %$row);
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

DBIx::Yakinny::Iterator - Iterator Object for Yakinny

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
