package DBIx::Yakinny::Iterator;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite (
    ro => [qw/sth row_class/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next {
    my $self = shift;
    if (my $row = $self->sth->fetchrow_hashref) {
        return $self->row_class->new(%$row);
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

Fetch all items at once.

=back
