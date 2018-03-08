use strict;
use warnings;

use Data::Dumper;
use Test::More;
use HTTP::XSCookies qw[crush_cookie];

my $str = 'cookie.a=foo=bar; cookie.b=1234abcd; HttpOnly; no.value.cookie; Secure';
my $got = crush_cookie($str);
my $expected = {
    'cookie.b'        => '1234abcd',
    'cookie.a'        => 'foo=bar',
    'Secure'          => undef,
    'HttpOnly'        => undef,
    'no.value.cookie' => undef,
};

# print Dumper $got;
is_deeply($got, $expected, 'crushed cookie with no-value fields');

done_testing();
