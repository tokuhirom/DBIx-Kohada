package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use base qw/Class::Data::Inheritable/;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub add_column {
    my ($class, $name) = @_;
    no strict 'refs';
    *{"${class}::$name"} = sub { $_[0]->get_column($name) };
    push @{"${class}::COLUMNS"}, $name;
}

sub columns {
    my $class = shift;
    no strict 'refs';
    @{"${class}::COLUMNS"};
}

sub set_primary_key {
    my ($class, $name) = @_;
    no strict 'refs';
    *{"${class}::primary_key"} = sub { $name };
}

sub set_table {
    my ($class, $table) = @_;
    no strict 'refs';
    *{"${class}::table"} = sub { $table };
}

sub get_column {
    my ($self, $name) = @_;
    $self->{row}->{$name};
}

sub where_cond {
    my ($self) = @_;
    +{ map { $_ => $self->get_column($_) } @{ $self->primary_key } }
}

sub update {
    my ($self, $attr) = @_;
    my ($sql, @binds) = $self->yakinny->query_builder->update($self->table, $attr, $self->where_cond);
    $self->yakinny->dbh->do($sql, {}, @binds) == 1 or die;
}

sub delete {
    my $self = shift;
    my ($sql, @binds) = $self->yakinny->query_builder->delete($self->table, $self->where_cond);
    $self->yakinny->dbh->do($sql, {}, @binds) == 1 or die;
}

sub refetch {
    my $self = shift;

    return $self->yakinny->single(
        $self->table => +{
            map { $_ => $self->get_column($_) }
               @{ $self->primary_key }
        }
    );
}

sub yakinny {
    my $y = $_[0]->{yakinny};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Yakinny object in this instance(This situation is caused by Storable::freeze).");
    }
}

# storable stuff
{
    our $thaw_yakinny;

    sub STORABLE_freeze {
        my ($self, $is_cloning) = @_;
        return if $is_cloning;
        my $to_serialize = +{%$self};
        delete $to_serialize->{yakinny};
        return (Storable::freeze($to_serialize));
    }

    sub STORABLE_thaw {
        my ($self, $cloning, $ice) = @_;
        %$self = %{ Storable::thaw($ice) };
        $self->{yakinny} = $thaw_yakinny;
    }
}

1;
