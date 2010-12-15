use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Row;
use Carp ();

*_subname = eval { require Sub::Name; \&Sub::Name::subname } || sub { $_[1] };

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr, selected_columns => [keys %{$attr{row_data}}]}, $class;
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

# ------------------------------------------------------------------------- 
# schema

sub table { Carp::croak("Call 'set_table' method before call this method") }

sub primary_key {
    Carp::croak("Call 'set_primary_key' method before call this method");
}

sub set_table {
    my ($class, $table) = @_;
    Carp::croak("This is a class method") if ref $class;
    Carp::croak("Usage: __PACKAGE__->set_table(\$table: Str)") unless defined $table;

    no strict 'refs';
    *{"${class}::table"} = _subname("${class}::table" => sub { $table });
}

sub set_primary_key {
    my $class = shift;
    my @pk = @_;
    Carp::croak("This is a class method") if ref $class;

    no strict 'refs';
    *{"${class}::primary_key"} = _subname("${class}::primary_key" => sub { wantarray ? @pk : \@pk });
}

our %COLUMNS;
sub add_column {
    my $class = shift;
    Carp::croak("This is a class method") if ref $class;
    my $name = shift;

    push @{$COLUMNS{$class}}, $name;
    $class->mk_column_accessors($name);
}

sub columns {
    my $c = $COLUMNS{ref($_[0]) || $_[0]};
    wantarray ? @$c : $c;
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


# ------------------------------------------------------------------------- 
# operations

sub where_cond {
    my ($self) = @_;
    my @pk = @{$self->primary_key};
    Carp::confess("You cannot call this method whithout primary key") unless @pk;
    return +{ map { $_ => $self->get_column($_) } @pk };
}

sub refetch {
    my $self = shift;
    return $self->kohada->single( $self->table => $self->where_cond );
}

sub kohada {
    Carp::confess($_[0] . "->kohada is a instance method.") unless ref $_[0];

    my $y = $_[0]->{kohada};
    if ($y) {
        return $y;
    } else {
        Carp::croak("There is no DBIx::Kohada object in this instance(This situation is caused by Storable::freeze).");
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
        $self->call_trigger('before_update', $attr);
        $self->kohada->update_row($self, $attr);
        $self->call_trigger('after_update', $attr);
    }
    return;
}

sub delete {
    my $self = shift;
    $self->call_trigger('before_delete');
    $self->kohada->delete_row($self);
    $self->call_trigger('after_delete');
    return;
}

# ------------------------------------------------------------------------- 
# trigger

our %TRIGGERS;
sub add_trigger {
    my ($class, $point, $code) = @_;
    Carp::croak("Do not call this method directly. You should inherit this class.") if $class eq __PACKAGE__;
    push @{$TRIGGERS{$class}->{$point}}, $code;
}
sub call_trigger {
    my ($self, $point, @args) = @_;
    for my $code (@{$TRIGGERS{ref $self || $self}->{$point} || []}) {
        $code->($self, @args);
    }
}
sub has_trigger {
    my ($class, $point) = @_;
    Carp::croak("Do not call this method directly. You should inherit this class.") if $class eq __PACKAGE__;
    $TRIGGERS{$class}->{$point} ? 1 : 0;
}

# ------------------------------------------------------------------------- 
# inflate/deflate

our %INFLATE_RULE;
our %DEFLATE_RULE;

sub set_inflation_rule {
    my ($class, $column_name, $code) = @_;
    Carp::croak("This is a class method, not a instance method") if ref $class;
    Carp::croak("Do not call this method directly. You should inherit this class.") if $class eq __PACKAGE__;
    $INFLATE_RULE{$class}->{$column_name} = $code;
}

sub set_deflation_rule {
    my ($class, $column_name, $code) = @_;
    Carp::croak("This is a class method, not a instance method") if ref $class;
    Carp::croak("Do not call this method directly. You should inherit this class.") if $class eq __PACKAGE__;
    $DEFLATE_RULE{$class}->{$column_name} = $code;
}

sub inflate {
    my ($self, $column_name, $value) = @_;
    my $code = $INFLATE_RULE{(ref $self)}->{$column_name};
    return $code ? $code->($value, $self->kohada) : $value;
}

sub deflate {
    my ($class, $column_name, $value) = @_;
    return $value unless defined $value;
    return $value if ref $value && ref $value eq 'SCALAR'; # to ignore \"foo + 1"

    my $code = $DEFLATE_RULE{(ref $class || $class)}->{$column_name};
    return $code ? $code->($value) : $value;
}

1;
__END__

=for test_synopsis
my ($db);

=head1 NAME

DBIx::Kohada::Row - Row class

=head1 SYNOPSIS

    package MyApp::DB::Row::User;
    use parent qw/DBIx::Kohada::Row/;
    __PACKAGE__->set_table('user');
    __PACKAGE__->set_primary_key('user_id');
    __PACKAGE__->add_column($_) for qw/user_id name email/;

    package main;
    MyApp::DB::Row::User->new(row_data => {user_id => 1, name => 'john'}, kohada => $db, );

=head1 DESCRIPTIOON

This is a row class for L<DBIx::Kohada>. This is a active record.

=head1 SCHEMA METHODS

=over 4

=item __PACKAGE__->set_table($table: Str);

Set the table name for the class.

=item __PACKAGE__->set_primary_key((@primary_keys: Array[Str])

Set the primary key for the class.

=item __PACKAGE__->add_column($column_name)

Add the column.

=item __PACKAGE__->table()

=item my $table_name = $row->table()

Get the table name for the class.

=item my @columns = __PACKAGE__->columns()

=item my $columns = __PACKAGE__->columns()

Get the columns.

=back

