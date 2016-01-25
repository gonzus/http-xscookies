use strict;
use warnings;

use Test::More;
use HTTP::XSCookie;

eval { require Test::MemoryGrowth; 1; }
  or plan skip_all => 'Test::MemoryGrowth is needed for this test';

my $cookie = 'foo=bar; path=/';

Test::MemoryGrowth::no_growth(sub {
    Devel::Cookie::crush_cookie($cookie);
});

done_testing;
