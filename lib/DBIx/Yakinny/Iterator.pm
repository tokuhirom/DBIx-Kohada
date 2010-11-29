package DBIx::Yakinny::Iterator;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite;

Class::Accessor::Lite->mk_accessors(qw/sth table yakinny/);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next {
    my $self = shift;
    if (my $row = $self->sth->fetchrow_hashref) {
        my $row_class = $self->yakinny->schema->get_class_for($self->table);
        return $row_class->new(yakinny => $self->yakinny, row => $row);
    } else {
        $self->sth->finish;
        return;
    }
}

1;

