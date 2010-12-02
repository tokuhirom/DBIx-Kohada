use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'DBIx-Yakinny';
all_from 'lib/DBIx/Yakinny.pm';
readme_markdown_from 'lib/DBIx/Yakinny.pm';

requires 'SQL::Abstract::Plugin::InsertMulti' => 0.03;
requires 'DBI';
requires 'SQL::Abstract::Limit';
requires 'parent';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
test_requires 'Test::Requires';
author_tests('xt');
WriteAll;
