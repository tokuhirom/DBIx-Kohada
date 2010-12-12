use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Yakinny::Row;
use Carp ();

our %INFLATE_RULE;
our %DEFLATE_RULE;

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr, selected_columns => [keys %{$attr{row_data}}]}, $class;
}

sub table {
    my $self = shift;
    return $self->{table} if exists $self->{table};
    Carp::confess "Missing mandatory parameter 'table' for DB related operation";
}

sub columns {
    my $self = shift;
    keys %{$self->{row_data}};
}

sub get_column {
    my ($self, $name) = @_;
    return $self->{row_data}->{$name} if exists $self->{row_data}->{$name};
    Carp::croak("$name was not fetched by query.");
}

sub get_columns {
    my ($self) = @_;
    return +{ map { $_ => $self->{row_data}->{$_} } $self->columns };
}

sub where_cond {
    my ($self) = @_;
    my @pk = @{$self->table->primary_key};
    Carp::confess("You cannot call this method whithout primary key") unless @pk;
    return +{ map { $_ => $self->get_column($_) } @pk };
}

sub delete {
    my $self = shift;
    $self->yakinny->delete_row($self);
    return;
}

sub refetch {
    my $self = shift;
    return $self->yakinny->single( $self->table->name => $self->where_cond );
}

sub yakinny {
    Carp::confess($_[0] . "->yakinny is a instance method.") unless ref $_[0];

    my $y = $_[0]->{yakinny};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Yakinny object in this instance(This situation is caused by Storable::freeze).");
    }
}

sub mk_column_accessors {
    my $class = shift;
    no strict 'refs';
    for my $name (@_) {
        *{"${class}::$name"} = sub {
            return $_[0]->set_column($name, $_[1]) if @_==2;
            return $_[0]->inflate( $name => $_[0]->get_column($name) );
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
    my ($self, $more_attr) = @_;
    my $attr = $self->get_dirty_columns();
    if ($more_attr) {
        Carp::croak "Usage: ->update([\%more_attr])" unless ref $more_attr eq 'HASH';
        while (my ($col, $val) = each %$more_attr) {
            Carp::croak("You passed '$col' set to '$val', but it is dirty column, overwritten by '$attr->{$col}'") if exists $attr->{$col};
            $attr->{$col} = $val;
        }
    }
    if (%$attr) {
        $self->yakinny->update_row($self, $attr);
    }
    return;
}

# ------------------------------------------------------------------------- 
# inflate/deflate

sub set_inflation_rule {
    my ($class, $column_name, $code) = @_;
    Carp::croak("This is a class method, not a instance method") if ref $class;
    $INFLATE_RULE{$class}->{$column_name} = $code;
}

sub set_deflation_rule {
    my ($class, $column_name, $code) = @_;
    Carp::croak("This is a class method, not a instance method") if ref $class;
    $DEFLATE_RULE{$class}->{$column_name} = $code;
}

sub inflate {
    my ($self, $column_name, $value) = @_;
    my $code = $INFLATE_RULE{(ref $self)}->{$column_name};
    return $code ? $code->($value, $self->yakinny) : $value;
}

sub deflate {
    my ($class, $column_name, $value) = @_;
    return $value unless defined $value;
    return $value if ref $value && ref $value eq 'SCALAR'; # to ignore \"foo + 1"

    my $code = $DEFLATE_RULE{(ref $class || $class)}->{$column_name};
    return $code ? $code->($value) : $value;
}

1;
