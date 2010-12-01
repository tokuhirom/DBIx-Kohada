#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use DBI;
use Scalar::Util qw/blessed/;
use Carp;

my $last_binds;
my $dbh = DBI->connect('dbi:SQLite:','','', {
    RaiseError => 1,
    Callbacks  => {
        ChildCallbacks => {
            execute => sub {
                my ($obj, @binds) = @_;
                my $stmt = $obj->{Database}->{Statement};
                $stmt =~ s/\?/'$_'/ for @binds;
                $last_binds = \@binds;
                print STDERR "DBI TRACE: " . $stmt, "\n";
                return;
            },
        },
    },
    HandleError => sub {
        my ($msg, $h) = @_;
        unless (blessed $h) {
            Carp::croak $msg;
        }
        if ($h->isa('DBI::st')) {
            my $stmt = $h->{Database}->{Statement};
            if ($last_binds) {
                $stmt =~ s/\?/'$_'/ for @$last_binds;
            }
            my $msg = '@@@@@@@@@@@@@@@@@@@@@@@@@' . "\n";
            $msg .= '@@ YAKINNY ERROR        @' . "\n";
            $msg .= '@@ ' . $stmt . " @@\n";
            $msg .= '@@@@@@@@@@@@@@@@@@@@@@@@@' . "\n\n";
            Carp::croak $msg;
        } else {
            Carp::croak $msg;
        }
    },
});
$dbh->do(q{create table job (func primary key, time)});

{
    my $sth = $dbh->prepare('select * from job where func = ? AND time=?');
    $sth->execute('abra', 'catabra');
}

# error
for (1..3) {
    my $sth = $dbh->prepare('INSERT INTO job (func) VALUES (?)');
    $sth->execute("FAIL") or die;
}
