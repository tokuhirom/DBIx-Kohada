package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use Carp ();
use DBIx::Yakinny;

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

# TODO: alias support?
sub add_column {
    my ($class, $stuff) = @_;
    $stuff = +{ COLUMN_NAME => $stuff } unless ref $stuff;
    my $name = $stuff->{COLUMN_NAME} || Carp::croak "missing COLUMN_NAME";
    no strict 'refs';
    *{"${class}::$name"} = $DBIx::Yakinny::FATAL ? sub { $_[0]->get_column($name) } : sub { $_[0]->{$name} };
    push @{"${class}::COLUMNS"}, $stuff;
}

sub columns {
    my $class = shift;
    no strict 'refs';
    map { $_->{COLUMN_NAME} } @{"${class}::COLUMNS"};
}

sub set_primary_key {
    my ($class, $pk) = @_;
    $pk = [$pk] unless ref $pk;
    no strict 'refs';
    *{"${class}::primary_key"} = sub { $pk };
}

sub set_table {
    my ($class, $table) = @_;
    no strict 'refs';
    *{"${class}::table"} = sub { $table };
}

sub get_column {
    my ($self, $name) = @_;
    return $self->{$name} if exists $self->{$name};
    Carp::croak("$name was not fetched by query.");
}

sub get_columns {
    my ($self, $name) = @_;
}

sub where_cond {
    my ($self) = @_;
    my @pk = @{$self->primary_key};
    Carp::confess("You cannot call this method whithout primary key") unless @pk;
    return +{ map { $_ => $self->get_column($_) } @pk };
}

sub update {
    my ($self, $attr) = @_;
    $self->yakinny->update_row($self, $attr);
    return;
}

sub delete {
    my $self = shift;
    $self->yakinny->delete_row($self);
    return;
}

sub refetch {
    my $self = shift;
    return $self->yakinny->single( $self->table => $self->where_cond );
}

sub yakinny {
    my $y = $_[0]->{__yakinny};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Yakinny object in this instance(This situation is caused by Storable::freeze).");
    }
}

1;
