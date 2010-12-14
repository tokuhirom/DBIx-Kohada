use strict;
use warnings;
use Test::More;

$INC{'Plugin/Foo.pm'}++;
$INC{'Plugin/Bar.pm'}++;

{
    package Plugin::Foo;
    our @EXPORT = qw/foo/;
    sub foo { 123 }
}
{
    package Plugin::Bar;
    our @EXPORT = qw/foo/;
    sub foo { 456 }
}
{
    package MyApp::DB;
    use parent qw/DBIx::Kohada/;
    __PACKAGE__->load_plugin('+Plugin::Foo');
    __PACKAGE__->load_plugin('+Plugin::Bar', {alias => {foo => 'bar'}});
}

{
    is(MyApp::DB->foo(), 123);
    is(MyApp::DB->bar(), 456, 'alias works');
}

done_testing;

