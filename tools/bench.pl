#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Dumbbench;
use Cookie::Baker::XS ();
use Devel::Cookie ();

my $cookie = 'foo=bar; path=/';

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,
    initial_runs         => 20,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        name => 'Cookie::Baker::XS',
        code => sub {
            for(1..1e5){
                Cookie::Baker::XS::crush_cookie($cookie);
            }
        },
    ),

    Dumbbench::Instance::PerlSub->new(
        name => 'Devel::Cookie',
        code => sub {
            for(1..1e5){
                Devel::Cookie::crush_cookie($cookie);
            }
        },
    ),
);

$bench->run;
$bench->report;

