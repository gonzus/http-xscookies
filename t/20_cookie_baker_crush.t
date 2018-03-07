use strict;
use warnings;

use Data::Dumper;
use Test::More;
use HTTP::XSCookies qw[crush_cookie bake_cookie];

exit main();

sub main {
    test_crush_cookie();

    done_testing();
    return 0;
}

sub test_crush_cookie {
    my $longkey = 'x'x1024;

    my @tests = (
        [ 't00', 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't01', 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't02', 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't03', 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;   ', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
        [ 't04', 'Foo=Bar; XXX=Foo%20Bar   ; YYY', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }],
        [ 't05', 'Foo=Bar; XXX=Foo%20Bar   ; YYY;', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }],
        [ 't06', 'Foo=Bar; XXX=Foo%20Bar   ; YYY; ', { Foo => 'Bar', XXX => 'Foo Bar', YYY => undef }],
        [ 't07', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=', { Foo => 'Bar', XXX => 'Foo Bar', YYY => "" }],
        [ 't08', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=;', { Foo => 'Bar', XXX => 'Foo Bar', YYY => "" }],
        [ 't09', 'Foo=Bar; XXX=Foo%20Bar   ; YYY=; ', { Foo => 'Bar', XXX => 'Foo Bar',YYY => "" }],
        [ 't10', "Foo=Bar; $longkey=Bar", { Foo => 'Bar', $longkey => 'Bar'}],
        [ 't11', "Foo=Bar; $longkey=Bar; Bar=Baz", { Foo => 'Bar', $longkey => 'Bar', 'Bar'=>'Baz'}],
        [
            't20', 'product_data=blah; Expires=Mon, 30-Oct-2017 19:02:53 GMT; Path=/; HttpOnly',
            {
                product_data => 'blah',
                Expires => 'Mon, 30-Oct-2017 19:02:53 GMT',
                Path => '/',
                HttpOnly => undef,
            },
        ],
        [
            't21', 'product_data=blah; HttpOnly; Expires=Mon, 30-Oct-2017 19:02:53 GMT',
            {
                product_data => 'blah',
                HttpOnly => undef,
                Expires => 'Mon, 30-Oct-2017 19:02:53 GMT',
            },
        ],
        [ 't30', '', {} ],
        [ 't31', undef, {} ],
        [ 't40', 'foo=bar%26baz; Secure', { foo => [qw/bar baz/], Secure => undef } ],
    );

    for my $test (@tests) {
        my $got = crush_cookie($test->[1]);
        is_deeply( $got, $test->[2], $test->[0] );
    }
}
