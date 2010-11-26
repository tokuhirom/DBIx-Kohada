package DBIx::Yakinny;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(__PACKAGE__, qw/dbh schema/);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    return bless {%args}, $class;
}

sub search  { ... }
sub insert  { ... }
sub update  { ... }
sub replace { ... }

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Yakinny -

=head1 SYNOPSIS

    package MyApp::DB::Schema;
    use base qw/DBIx::Yakinny::Schema/;

    __PACKAGE__->register_table(
        class   => 'MyApp::DB::User',
        table   => 'user',
        columns => [qw/user_id name email/],
        pk      => 'user_id',
    );

    package MyApp::DB::User;
    use base qw/DBIx::Yakinny::Row/;

    __PACKAGE__->add_trigger(
        'BEFORE_INSERT' => sub {
            my $attr = shift;
            $attr->{token} ||= rand();
        }
    );

    package main;
    use MyApp::DB::Schema;
    use DBIx::Yakinny::Schema;
    use DBI;

    my $dbh = DBI->connect(...);
    my $db = DBIx::Yakinny->new(schema => 'MyApp::DB::Schema', dbh => $dbh);
    $db->dbh; # => #dbh
    my $user = $db->insert('user' => {name => 'john', email => 'john@exapmle.com'});
    say $user->name; # => john
    $user->name('mark');
    $user->update;

    my @users = $db->search_by_sql('user' => q{SELECT * FROM user WHERE name LIKE 'dai%'});

    my $user = $db->single('user' => {user_id => 3});
    my $iter = $db->search('user' => {user_id => 3});
    my @users = $db->search('user' => {user_id => 3});

=head1 DESCRIPTION

DBIx::Yakinny is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
