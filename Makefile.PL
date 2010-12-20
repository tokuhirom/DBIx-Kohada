use inc::Module::Install;
use Module::Install::AuthorTests;

name 'DBIx-Kohada';
all_from 'lib/DBIx/Kohada.pm';

requires 'DBI';
requires 'SQL::Maker' => '0.02';
requires 'parent';
requires 'DBIx::TransactionManager' => 1.02;
requires 'Class::Accessor::Lite'    => 0.05;
requires 'DBIx::Inspector'          => 0.04;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
test_requires 'Test::Requires';
test_requires 'DBD::SQLite';
author_tests('xt');
WriteAll;
