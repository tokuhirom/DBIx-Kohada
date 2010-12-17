use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada::Plugin::Pager::MySQLFoundRows;
use Data::Page;
use DBIx::Kohada::Iterator;
use Carp ();

our @EXPORT = qw/search_with_pager/;

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
__END__

=head1 NAME

DBIx::Kohada::Plugin::Pager::MySQLFoundRows - Paginate with SQL_CALC_FOUND_ROWS

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
    __PACKAGE__->load_plugin('Pager::MySQLFoundRows');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5});

=head1 DESCRIPTION

This is a helper class for pagination. This helper only supports B<MySQL>.
Since this plugin uses SQL_CALC_FOUND_ROWS for calcurate total entries.

=head1 METHODS

=over 4

=item my (\@rows, $pager) = $db->search_with_pager($table, \%where, \%opts);

Select from database with pagination.

The arguments are mostly same as C<$db->search()>. But two additional options are available.

=over 4

=item $opts->{page}

Current page number.

=item $opts->{rows}

The number of entries per page.

=back

This method returns ArrayRef[DBIx::Kohada::Row] and instance of L<DBIx::Kohada::Plugin::Pager::Page>.

=back

=head1 AUTHOR

Tokuhiro Matsuno

