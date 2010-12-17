use strict;
use warnings;
use utf8;

package DBIx::Kohada::Plugin::Pager;
use Carp ();
use DBI;

our @EXPORT = qw/search_with_pager/;

sub search_with_pager {
    my ($self, $table, $where, $opt) = @_;

    my $row_class = $self->schema->table_name2row_class($table) or Carp::croak("'$table' is unknown table");

    my $page = $opt->{page};
    my $rows = $opt->{rows};
    for (qw/page rows/) {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
    }

    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where, +{
        %$opt,
        limit => $rows + 1,
        offset => $rows*($page-1),
    });
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@bind) or Carp::croak $self->dbh->errstr;

    my $ret = [$self->new_iterator(sth => $sth, row_class => $row_class, table => $table, query => $sql)->all];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) { pop @$ret }

    my $pager = DBIx::Kohada::Plugin::Pager::Page->new(
        entries_per_page     => $rows,
        current_page         => $page,
        has_next             => $has_next,
        entries_on_this_page => $sth->rows,
    );

    return ($ret, $pager);
}

package DBIx::Kohada::Plugin::Pager::Page;
use Class::Accessor::Lite (
    ro => [qw/entries_per_page current_page has_next entries_on_this_page/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next_page {
    my $self = shift;
    $self->has_next ? $self->current_page + 1 : undef;
}

sub previous_page { shift->prev_page(@_) }
sub prev_page {
    my $self = shift;
    $self->current_page > 1 ? $self->current_page - 1 : undef;
}

1;
__END__

=head1 NAME

DBIx::Kohada::Plugin::Pager - Pager

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
    __PACKAGE__->load_plugin('Pager');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5});

=head1 DESCRIPTION

This is a helper for pagination.

This pager fetches "entries_per_page + 1" rows. And detect "this page has a next page or not".

=head1 METHODS

=over 4

=item my (\@rows, $pager) = $db->search_with_pager($table, \%where, \%opts)

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

=head1 DBIx::Kohada::Plugin::Pager::Page

B<search_with_pager> method returns the instance of DBIx::Kohada::Plugin::Pager::Page. It gives paging information.

=head2 METHODS

=over 4

=item $pager->entries_per_page()

The number of entries per page('rows'. you provided).

=item $pager->current_page()

Returns: fethced page number.

=item $pager->has_next()

The page has next page or not in boolean value.

=item $pager->entries_on_this_page()

How many entries on this page?

=item $pager->next_page()

The page number of next page.

=item $pager->previous_page()

The page number of previous page.

=item $pager->prev_page()

Alias for C<$pager->previous_page()>.

=back
