use strict;
use warnings;

use Test::More;
use HTTP::XSCookies qw[bake_cookie];

exit main();

sub main {
    test_bake_cookie();

    done_testing();
    return 0;
}

sub test_bake_cookie {
    my $now = time();

    my @tests = (
        [ 't00', 'foo', 'val', 'foo=val'],
        [ 't01', 'foo', { value => 'val' }, 'foo=val'],
        [ 't02', 'foo', { value => 'foo bar baz' }, 'foo=foo%20bar%20baz'],
        [ 't03', 'foo', { value => 'val',expires => undef }, 'foo=val'],
        [ 't04', 'foo', { value => 'val',path => '/' }, 'foo=val; path=/'],
        [ 't05', 'foo', { value => 'val',path => '/', secure => 1, httponly => 0 }, 'foo=val; path=/; secure'],
        [ 't06', 'foo', { value => 'val',path => '/', secure => 0, httponly => 1 }, 'foo=val; path=/; HttpOnly'],
        [ 't07', 'foo', { value => 'val',expires => 'now' }, sprintf('foo=val; expires=%s', fmt($now))],
        [ 't08', 'foo', { value => 'val',expires => $now + 24*60*60 }, sprintf('foo=val; expires=%s', fmt($now + 24*60*60))],
        [ 't09', 'foo', { value => 'val',expires => '1s'  }, sprintf('foo=val; expires=%s', fmt($now + 1))],
        [ 't10', 'foo', { value => 'val',expires => '+10' }, sprintf('foo=val; expires=%s', fmt($now + 10))],
        [ 't11', 'foo', { value => 'val',expires => '+1m' }, sprintf('foo=val; expires=%s', fmt($now + 60))],
        [ 't12', 'foo', { value => 'val',expires => '+1h' }, sprintf('foo=val; expires=%s', fmt($now + 60*60))],
        [ 't13', 'foo', { value => 'val',expires => '+1d' }, sprintf('foo=val; expires=%s', fmt($now + 24*60*60))],
        [ 't14', 'foo', { value => 'val',expires => '-1d' }, sprintf('foo=val; expires=%s', fmt($now - 24*60*60))],
        [ 't15', 'foo', { value => 'val',expires => '+1M' }, sprintf('foo=val; expires=%s', fmt($now + 30*24*60*60))],
        [ 't16', 'foo', { value => 'val',expires => '+1y' }, sprintf('foo=val; expires=%s', fmt($now + 365*24*60*60))],
        [ 't17', 'foo', { value => 'val',expires => '0' }, sprintf('foo=val; expires=%s', fmt(0))],
        [ 't18', 'foo', { value => 'val',expires => '-1' }, sprintf('foo=val; expires=%s', fmt($now - 1))],
        [ 't19', 'foo', { value => 'val',expires => 'foo' }, 'foo=val; expires=foo'],
    );

    for my $test (@tests) {
        printf("Running %s...\n", $test->[2]);
        is( sc(bake_cookie($test->[1], $test->[2])), sc($test->[3]), $test->[0] );
    }
}

sub fmt {
    my ($time) = @_;

    my @Mon = qw{
            Jan
            Feb
            Mar
            Apr
            May
            Jun
            Jul
            Aug
            Sep
            Oct
            Nov
            Dec
        };
    my @Day = qw{
            Sun
            Mon
            Tue
            Wed
            Thu
            Fri
            Sat
        };

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    return sprintf("%3s, %02d-%3s-%04d %02d:%02d:%02d GMT",
                   $Day[$wday], $mday, $Mon[$mon], $year+1900,
                   $hour, $min, $sec);
}

sub sc {
    my ($str) = @_;

    my @parts = split('; ', $str);
    return $str unless @parts > 1;

    my $first = $parts[0];
    @parts = @parts[1..$#parts];
    my %fields;
    for my $part (@parts) {
        my @p = split('=', $part);
        next unless @p == 2;
        $fields{$p[0]} = $p[1];
    }

    $str = $first;
    for my $key (sort keys %fields) {
        $str .= sprintf("; %s=%s", $key, $fields{$key});
    }
    return $str;
}
