package DBIx::Yakinny::Iterator;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite;

Class::Accessor::Lite->mk_accessors(qw/sth _row_class _yakinny/);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next {
    my $self = shift;
    if (my $row = $self->sth->fetchrow_hashref) {
        return $self->_row_class->new(__yakinny__ => $self->_yakinny, %$row);
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

