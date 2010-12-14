use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Plugin::Pager::MySQLFoundRows;
use Data::Page;
use DBIx::Kohada::Iterator;
use Carp ();

use Role::Tiny;

sub search_with_pager {
    my ($self, $table, $where, $opt) = @_;

    my $row_class = $self->schema->table_name2row_class($table) or Carp::croak("'$table' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};

    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where, +{
        %$opt,
        limit => $rows,
        offset => $rows*($page-1),
        prefix => 'SELECT SQL_CALC_FOUND_ROWS ',
    });
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@bind) or Carp::croak $self->dbh->errstr;
    my $total_entries = $self->dbh->selectrow_array(q{SELECT FOUND_ROWS()});

    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class);

    my $pager = Data::Page->new();
    $pager->entries_per_page($rows);
    $pager->current_page($page);
    $pager->total_entries($total_entries);

    return ([$iter->all], $pager);
}

1;
