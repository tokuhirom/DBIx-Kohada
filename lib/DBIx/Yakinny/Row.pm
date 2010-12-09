package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use parent qw/DBIx::Yakinny::Row::Base/;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub add_column_accessors {
    my $class = shift;
    no strict 'refs';
    for my $name (@_) {
        *{"${class}::$name"} = sub {
            return $_[0]->{row_data}->{$name} if exists $_[0]->{row_data}->{$name};
            Carp::croak("$name was not fetched by query.");
        };
    }
}

sub update {
    my ($self, $attr) = @_;
    $self->yakinny->update_row($self, $attr);
    return;
}

1;
