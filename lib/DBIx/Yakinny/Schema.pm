package DBIx::Yakinny::Schema;
use strict;
use warnings;
use utf8;
use Carp ();

sub new {
    my $class = shift;
    bless {'map' => +{}}, $class;
}

sub get_row_class_for {
    my ($self, $table) = @_;
    return $self->{table_name2row_class}->{$table};
}

sub get_table_info_for {
    my ($self, $table) = @_;
    return $self->{table_name2obj}->{$table};
}

sub get_table_object_from_row_class {
    my ($self, $row_class) = @_;
    return $self->{row_class2table_obj}->{$row_class};
}

sub tables {
    my $self = shift;
    return values %{$self->{table_name2obj}};
}

# my $table = DBIx::Yakinny::Schema::Table->new(name => 'user', columns => [map {+{ COLUMN_NAME => $_}} qw/user_id name email/], primary_key => user_id);
# $schema->map_table($table => 'MyApp::DB::Row::User');
sub map_table {
    my ($self, $table, $row_class) = @_;
    $self->{table_name2obj}->{$table->name} = $table;
    $self->{table_name2row_class}->{$table->name} = $row_class;
    $self->{row_class2table_obj}->{$row_class} = $table;
}

1;
