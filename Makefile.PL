use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'DBIx-Yakinny';
all_from 'lib/DBIx/Yakinny.pm';
readme_markdown_from 'lib/DBIx/Yakinny.pm';

requires 'DBI';
requires 'SQL::Maker';
requires 'parent';
requires 'DBIx::TransactionManager' => 1.02;
requires 'Role::Tiny';
requires 'Class::Method::Modifiers';
requires 'Class::Accessor::Lite' => 0.05;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
test_requires 'Test::Requires';
author_tests('xt');
WriteAll;
