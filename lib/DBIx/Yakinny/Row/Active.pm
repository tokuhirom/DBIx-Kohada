package DBIx::Yakinny::Row::Active;
use strict;
use warnings;
use utf8;
use parent qw/DBIx::Yakinny::Row::Base/;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr, selected_columns => [keys %{$attr{row_data}}]}, $class;
}

sub columns {
    my $self = shift;
    keys %{$self->{row_data}};
}

sub add_column_accessors {
    my $class = shift;
    no strict 'refs';
    for my $name (@_) {
        *{"${class}::$name"} = sub {
            return $_[0]->set_column($name, $_[1]) if @_==2;
            return $_[0]->get_column($name);
        };
    }
}

sub get_dirty_columns {
    my ($self) = @_;
    +{ map { $_ => $self->get_column($_) } keys %{$self->{dirty_columns}} };
}

sub set_column {
    my ($self, $col, $val) = @_;
    $self->{row_data}->{$col} = $val;
    $self->{dirty_columns}->{$col} = 1;
}

sub set_columns {
    my ($self, $data) = @_;
    while (my ($col, $val) = each %$data) {
        $self->set_column($col, $val);
    }
}

sub update {
    my ($self) = @_;
    Carp::confess('Usage: ' . __PACKAGE__ . "->update()") unless @_==1;
    my $attr = $self->get_dirty_columns();
    if (%$attr) {
        $self->yakinny->update_row($self, $attr);
    }
    return;
}

1;
__END__

=head1 NAME

DBIx::Yakinny::Row::Active - Class::DBI like active record.

=head1 SYNOPSIS


    my $user = $db->single(user => {user_id => $user_id});
    $user->name('john');
    $user->update();

