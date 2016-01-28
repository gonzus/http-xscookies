package HTTP::XSCookies;

use strict;
use warnings;

use XSLoader;
use parent 'Exporter';

our $VERSION = '0.000005';
XSLoader::load( 'HTTP::XSCookies', $VERSION );

our @EXPORT_OK = qw[bake_cookie crush_cookie];

1;

__END__

=pod

=encoding utf8

=head1 NAME

HTTP::XSCookies - Quick & dirty cookie mangling for Perl

=head1 VERSION

Version 0.000005

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Sawyer X

=item * p5pclub

=back
