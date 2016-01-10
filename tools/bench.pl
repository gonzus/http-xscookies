#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Dumbbench;
use Cookie::Baker ();
use Cookie::Baker::XS ();
use Devel::Cookie ();

# my $cookie = 'foo=bar; path=/';
#my $cookie = 'DV=; expires=Mon, 01-Jan-1990 00:00:00 GMT; path=/webhp; domain=www.google.com';
my $cookie = 'whv=MtW_XszVxqHnN6rHsX0d; expires=Wed, 07 Jan 2026 11:10:40 GMT; domain=.wikihow.com; path=';
my $iterations = 1e5;

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,
    initial_runs         => 20,
);

$bench->add_instances(
    # Dumbbench::Instance::PerlSub->new(
    #     name => 'Cookie::Baker',
    #     code => sub {
    #         for(1..$iterations){
    #             Cookie::Baker::crush_cookie($cookie);
    #         }
    #     },
    # ),

    Dumbbench::Instance::PerlSub->new(
        name => 'Cookie::Baker::XS',
        code => sub {
            for(1..$iterations){
                Cookie::Baker::XS::crush_cookie($cookie);
            }
        },
    ),

    Dumbbench::Instance::PerlSub->new(
        name => 'Devel::Cookie',
        code => sub {
            for(1..$iterations){
                Devel::Cookie::crush_cookie($cookie);
            }
        },
    ),
);

$bench->run;
$bench->report;
