package DBIx::Yakinny::Row;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my $class = shift;
    my %attr = @_ == 1 ? %{$_[0]} : @_;
    return bless {%attr}, $class;
}

sub add_column {
    my ($class, $stuff) = @_;
    $stuff = +{ COLUMN_NAME => $stuff } unless ref $stuff;
    my $name = $stuff->{COLUMN_NAME} || Carp::croak "missing COLUMN_NAME";
    no strict 'refs';
    *{"${class}::$name"} = sub { $_[0]->{$name} };
    push @{"${class}::COLUMNS"}, $stuff;
}

sub columns {
    my $class = shift;
    no strict 'refs';
    my @columns = map { $_->{COLUMN_NAME} } @{"${class}::COLUMNS"};
    return wantarray ? @columns : \@columns;
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

# abstract methods
sub table       { Carp::confess "Please set table name before use" }
sub primary_key { Carp::confess "Please set table name before use" }

sub get_column {
    my ($self, $name) = @_;
    $self->{$name};
}

sub where_cond {
    my ($self) = @_;
    my @pk = @{$self->primary_key};
    Carp::confess("You cannot call this method whithout primary key") unless @pk;
    return +{ map { $_ => $self->get_column($_) } @pk };
}

1;
__END__

=head1 NAME

DBIx::Yakinny::Row - Row object

=head1 SYNOPSIS

    package MyApp::DB::Row::User;
    use parent qw/DBIx::Yakinny::Row/;
    __PACKAGE__->table('user');
    __PACKAGE__->add_column($_) for qw/user_id name email ctime/;
    __PACKAGE__->set_primary_key(qw/user_id/);

=head1 DESCRIPTION

This is a row object for Yakinny.

=head1 METHODS

=over 4

=item my @columns = $row->columns();

=item my $columns = $row->columns(); : ArrayRef

Get the columns info.

=item my $pk = $row->primary_key(); : ArrayRef

Get the primary keys in arrayref.

=item my $table_name = $row->table();

Get the table name.

=item my $data = $row->get_column($name)

Get the column data from row.

=item my $condition = $row->where_cond()

You can get the condition in hashref.
You can use it for re-fetch row from database.

    my $condition = $row->where_cond();
    $db->single($row->table, $condition); # this is same as $db->refetch($row)


=back

