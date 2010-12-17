use strict;
use warnings FATAL => 'all';
use utf8;

package DBIx::Kohada;
use 5.008001;
our $VERSION = '0.01';
use Class::Accessor::Lite (
    ro => [qw/dbh/], # because if it change this attribute, then it breaks TransactionManger's state.
    rw => [qw/query_builder schema/],
);
use Carp ();
use Module::Load ();
use DBIx::TransactionManager;

use DBIx::Kohada::Iterator;
use DBIx::Kohada::AnonRow;
use DBIx::Kohada::QueryBuilder;

$Carp::Internal{ (__PACKAGE__) }++;

# utility
sub _ddf {
    my $value = shift;
    if ( defined $value && ref($value) ) {
        require Data::Dumper;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $value = Data::Dumper::Dumper($value);
    }
    $value;
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    for (qw/schema dbh/) {
        Carp::croak("missing mandatory parameter: $_") unless $args{$_};
    }
    my $quote_char =
         delete $args{quote_char}
      || $args{dbh}->get_info(29)
      || q{"};
    my $name_sep = delete $args{name_sep} || $args{dbh}->get_info(41) || q{.};

    my $self = bless {%args}, $class;
    $self->{query_builder} ||= DBIx::Kohada::QueryBuilder->new(
        driver     => $self->dbh->{Driver}->{Name},
        quote_char => $quote_char,
        name_sep   => $name_sep,
    );
    return $self;
}

sub new_iterator {
    my ($self, @args) = @_;
    return DBIx::Kohada::Iterator->new(@args, kohada => $self);
}

sub load_plugin {
    my ($class, $name, $opt) = @_;
    $name = $name =~ s/^\+// ? $name : "DBIx::Kohada::Plugin::$name";
    Module::Load::load($name);

    no strict 'refs';
    for my $meth ( @{"${name}::EXPORT"} ) {
        my $dest_meth = $opt->{alias} && $opt->{alias}->{$meth} ? $opt->{alias}->{$meth} : $meth;
        *{"${class}::${dest_meth}"} = *{"${name}::$meth"};
    }
}

sub single {
    my ($self, $table, $where, $opt) = @_;

    $self->search($table, $where, {%{$opt||{}}, limit => 1})->next;
}

sub search  {
    my ($self, $table, $where, $opt) = @_;
    my $row_class = $self->schema->table_name2row_class($table) or Carp::croak "Unknown table : $table";

    my ($sql, @bind) = $self->query_builder->select($table, [$row_class->columns], $where, $opt);
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@bind) or Carp::croak $self->dbh->errstr;
    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class, query => $sql);
    return wantarray ? $iter->all : $iter;
}

sub search_by_query_object {
    my ($self, $table_name, $query) = @_;
    Carp::croak('Usage: ->search_by_query_object($query)') unless ref $query;

    my $row_class;
    if (defined $table_name) {
        $row_class = $self->schema->table_name2row_class($table_name) or Carp::croak("unknown table : $table_name");
    } else {
        $row_class = 'DBIx::Kohada::AnonRow';
    }

    my $sql  = $query->as_sql();
    my @bind = $query->bind();
    my $sth = $self->dbh->prepare($sql) or Carp::croak(sprintf("search_by_query_object: $sql, %s", _ddf(\@bind)));
    $sth->execute(@bind) or Carp::croak $self->dbh->errstr;
    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class, query => $sql);
    return wantarray ? $iter->all : $iter;
}


sub search_by_sql {
    my ($self, $table, $sql, @binds) = @_;

    my $row_class;
    if (defined $table) {
        $row_class = $self->schema->table_name2row_class($table) or Carp::croak("unknown table : $table");
    } else {
        $row_class = 'DBIx::Kohada::AnonRow';
    }
    my $sth = $self->dbh->prepare($sql) or Carp::croak $self->dbh->errstr;
    $sth->execute(@binds) or Carp::croak $self->dbh->errstr;
    my $iter = $self->new_iterator(sth => $sth, row_class => $row_class, query => $sql);
    return wantarray ? $iter->all : $iter;
}

sub insert  {
    my ($self, $table, $values, $opt) = @_;

    my $row_class = $self->schema->table_name2row_class($table) or Carp::croak("'$table' is not registered in schema");
    $row_class->call_trigger("before_insert", $values);
    if ($row_class->has_trigger('after_insert')) {
        my $row = $self->_insert_or_replace($table, $values, $opt);
        $row->call_trigger("after_insert");
        return $row;
    } else {
        return $self->_insert_or_replace($table, $values, $opt);
    }
}

sub _insert_or_replace {
    my ($self, $table, $values, $opt) = @_;

    $self->_do_deflate($table, $values);
    my ($sql, @bind) = $self->query_builder->insert($table, $values, $opt);
    $self->dbh->do($sql, {}, @bind) or Carp::croak $sql . ' : ' . $self->dbh->errstr;
    if (defined wantarray) {
        # find row
        my $row_class = $self->schema->table_name2row_class($table) or Carp::croak("'$table' is not registered in schema");
        my $primary_key = $row_class->primary_key;
        if (@$primary_key == 0) {
            Carp::confess("Cannot retrieve row after insert row. Because table '$table' does not have a PRIMARY KEY");
        }
        if (@$primary_key == 1 && not exists $values->{$primary_key->[0]}) {
            return $self->retrieve($table => $self->last_insert_id($table));
        }

        my $criteria = {};
        for my $primary_key1 (@{$row_class->primary_key}) {
            $criteria->{$primary_key1} = $values->{$primary_key1};
        }
        return $self->single($table => $criteria);
    }
}

sub last_insert_id {
    my ($self, $table) = @_;

    # Note: DBD::Pg required $table name to get last_insert_id.
    return $self->dbh->last_insert_id("","",$table,"");
}

sub retrieve {
    my ($self, $table, $vals) = @_;
    $vals = [$vals] unless ref $vals;
    my $row_class = $self->schema->table_name2row_class($table) or Carp::croak("'$table' is not registered in schema");

    my $criteria = {};
    for (my $i=0; $i<@{$row_class->primary_key}; $i++) {
        my $k = $row_class->primary_key->[$i];
        my $v = $vals->[$i];
        $criteria->{$k} = $v;
    }
    return $self->single($table => $criteria);
}

sub bulk_insert {
    my ($self, $table, $rows) = @_;
    Carp::croak("Usage: \$kohada->bulk_insert(\$table, \@rows)") unless defined $rows;
    return unless @$rows; # because 0 rows makes invalid query

    my $driver = $self->dbh->{Driver}->{Name};
    if ($driver eq 'mysql') {
        my ($sql, @binds) = $self->query_builder->insert_multi($table, $rows);
        $self->dbh->do($sql, {}, @binds) or Carp::croak $self->dbh->errstr;
    } else {
        for my $row (@$rows) {
            # do not use $self->insert here for consistent behaivour
            my ($sql, @binds) = $self->query_builder->insert($table, $row);
            $self->dbh->do($sql, {}, @binds) or Carp::croak $self->dbh->errstr;
        }
    }
    return;
}

sub delete_row {
    my ($self, $row) = @_;

    my ($sql, @binds) = $self->query_builder->delete($row->table, $row->where_cond);
    $self->dbh->do($sql, {}, @binds) == 1 or die "FATAL";
}

sub update_row {
    my ($self, $row, $attr) = @_;

    $self->_do_deflate($row->table, $attr);
    my ($sql, @binds) = $self->query_builder->update($row->table, $attr, $row->where_cond);
    $self->dbh->do($sql, {}, @binds) == 1 or die "FATAL";
}

sub delete {
    my ($self, $table, $where) = @_;
    my ($sql, @binds) = $self->query_builder->delete($table, $where);
    $self->dbh->do($sql, {}, @binds);
}

sub update {
    my ($self, $table, $attr, $where) = @_;

    $self->_do_deflate($table, $attr);
    my ($sql, @binds) = $self->query_builder->update($table, $attr, $where);
    $self->dbh->do($sql, {}, @binds);
}

sub _do_deflate {
    my ($self, $table_name, $attr) = @_;
    my $row_class = $self->schema->table_name2row_class($table_name)
        or return; # since I don't need how to deflate it, but it's not critical issue.

    for my $col (keys %$attr) {
        $attr->{$col} = $row_class->deflate($col, $attr->{$col});
    }
}

sub new_query_object {
    my ($self) = @_;
    return $self->query_builder->new_select();
}

# ------------------------------------------------------------------------- 
# TransactionManger

sub transaction_manager {
    my $self = shift;
    $self->{transaction_manager} ||= DBIx::TransactionManager->new($self->dbh);
}

sub txn_scope {
    my $self = shift;
    return $self->transaction_manager->txn_scope();
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Kohada - ActiveRecord

=head1 SYNOPSIS

    package MyApp::DB::Row::User;
    use parent qw/DBIx::Kohada::Row/;
    __PACKAGE__->set_table('user');
    __PACKAGE__->set_primary_key('user_id');
    __PACKAGE__->add_column($_) for qw/user_id name email/;

    package main;
    use DBIx::Kohada::Schema;
    use DBIx::Kohada;
    use DBI;

    my $schema = DBIx::Kohada::Schema->new();
    $schema->register_row_class('MyApp::DB::Row::User');

    my $dbh = DBI->connect('dbi:SQLite:');
    my $db = DBIx::Kohada->new(
        dbh    => $dbh,
        schema => $schema,
    );
    $db->dbh; # => #dbh
    my $user = $db->insert('user' => {name => 'john', email => 'john@exapmle.com'});
    say $user->name; # => john
    $user->name('mark');
    $user->update;
    $user->delete();

    my @users = $db->search_by_sql('user' => q{SELECT * FROM user WHERE name LIKE 'dai%'});

    {
        my $user = $db->single('user' => {user_id => 3});
        my $iter = $db->search('user' => {user_id => 3});
        my @users = $db->search('user' => {user_id => 3});
    }

=head1 DESCRIPTION

DBIx::Kohada is yet another O/R mapper based on Active Record strategy.

=head1 WHY ANOTHER ONE?

I had using L<Class::DBI>, L<DBIx::Class>, and L<DBIx::Skinny>. But the three O/R Mappers are not enough for me.

=head1 METHODS

=over 4

=item my $db = DBIx::Kohada->new(%args);

Create new instance of DBIx::Kohada. The arguments are following:

=over 4

=item dbh

Database handle. Required.

=item schema

Instance of L<DBIx::Kohada::Schema>. Required.

=item quote_char

B<quote_char> for quoting indentifiers. Optional.

=item name_sep

B<name_sep> for join the identifiers. Optional.

=item query_builder

Instance of L<SQL::Maker>. Optional.

=back

=item my $iter = $db->new_iterator();

Create a new instance of L<DBIx::Kohada::Iterator>. It's normally used internally.

=item __PACKAGE__->load_plugin($name, \%opt);

You can load a plugin.

The arguments are:

=over 4

=item $name

The package name of the plugin. You can specify the "Pager" to load "DBIx::Kohada::Plugin::Pager", and "+MyApp::Plugin::Pager" for loading "MyApp::Plugin::Pager"(It's like Catalyst).

=item \%opt

You can specify the fllowing options:

=over 4

=item $opt->{alias} : HashRef

You can specify the method alias map to resolve method name conflict.

=back

=back

Return: nothing.

=item $db->single($table_name, \%where, \%opt);

Get the single row from database. The arguments are passing to C<< $db->search() >>.

=item my $iter = $db->search($table_name, \%where, \%opt);

=item my @rows = $db->search($table_name, \%where, \%opt);

SELECT rows from database.

The arguments are passing to C<< $db->query_builder >>.

B<Return>: Instance of iterator in scalar context, array of rows in list context.

=item my $query = $db->new_query_object();

Create a new instance of L<SQL::Maker::Select> object from the settings.

=item my $iter = $db->search_by_query_object($table_name, $query);

=item my @rows = $db->search_by_query_object($table_name, $query);

SELECT rows by C<< $query >>. C<< $query >> is a instance of SQL::Maker::Select.

C<< $table_name >> is using to determin row class. If it's undef, each rows are bless to L<DBIx::Kohada::AnonRow>.

B<Return>: Instance of iterator in scalar context, array of rows in list context.

=item my $iter = $db->search_by_sql($table_name, $sql, @binds);

=item my @rows = $db->search_by_sql($table_name, $sql, @binds);

SELECT rows by C<< $sql >>. C<< $sql >> is a string contains SQL.

C<< $table_name >> is using to determin row class. If it's undef, each rows are bless to L<DBIx::Kohada::AnonRow>.

B<Return>: Instance of iterator in scalar context, array of rows in list context.

=item my $row = $db->insert($table, \%values, \%opts);

Send the INSERT statement for the database. The SQL is construct by C<< $db->query_builder >>.

If you want to use "INSERT IGNORE" query, you can use C<<< $opt->{prefix} = "INSERT IGNORE " >>> .
If you want to use "REPLACE INTO ..." query, you can use C<< $opt->{prefix} = "REPLACE " >> .

B<Return>: In scalar context, this method sends SELECT query and get fresh data. In void context, this method don't works anymore. But if you set a B<AFTER_INSERT> trigger, Kohada sends SELECT query.

=item my $row = $db->retrieve($table, \@pk);

=item my $row = $db->retrieve($table, $pk);

Fetch a row by primary keys.

=item $db->bulk_insert($table, \@rows);

This method inserts much rows at once for performance.
This method B<*DON'T* CALL TRIGGERS> for performance. Be careful.

On MySQL, Kohada make multiline insert statement by L<SQL::Maker::Plugin::InsertMulti>. On other RDBMS, Kohada makes normal insert statement.

=item $db->delete($table, \%where);

DELETE rows from database. The query is constructed by C<< $db->query_builder >>.

B<Return>: none

=item $db->update($table, \%set, \%where);

UPDATE rows from database. The query is constructed by C<< $db->query_builder >>.

B<Return>: none

=item my $transaction_manager = $db->transaction_manager();

Returns instance of L<DBIx::TransactionManager> for C<< $db->dbh >>.

=item my $txn = $db->txn_scope();

Make a scopeed session. You can nest the transaction.

For more details, see L<DBIx::TransactionManager>.

=back

=head1 FAQ

=over 4

=item How do you use tracer like DBIx::Skinny::Profiler::Trace?

You can use tracer by DBI. And you can use the advanced tracer like this article: L<http://d.hatena.ne.jp/tokuhirom/20101201/1291196584>.

=item How do you use relationships?

It is not supported in core. You can write a plugin to do it.

=item How do you use on_connect_do like DBIC?

use $dbh->{Callbacks}->{connected}.

=item How do you use display the profiling result like L<DBIx::Skinny::Profiler>?

use L<Devel::KYTProf>.

=item How do you display pretty error message?

use DBI's callback functions. fore modetails, see eg/dbi-callback.pl.

=item How do you load child classes automatically?

use L<Module::Find>.

    use Module::Find;
    my $schema = DBIx::Kohada::Schema->new();
    $schema->register_row_class($_) for useall "MyApp::DB::Row";

=item How do you handle utf8 columns?

You should use B<mysql_enable_utf8>, B<sqlite_unicode>, etc.

=item Why don't you implement 'find_or_create' method?

It is not atomic operation. It makes issue at somtime.

=item How do you inflate by rule like DBIx::Skinny?

You can use following snipet code.

    for my $table ($schema->tables()) {
        my $row_classs = $schema->table_name2row_class($table->name);
        for my $column ($table->columns()) {
            if ($column eq 'ctime') {
                $row_class->set_inflation_rule(
                    $column => sub { Time::Piece->new($_[0]) }
                );
                $row_class->set_deflation_rule(
                    $column => sub { $_[0]->epoch }
                );
            }
        }
    }

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
