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

