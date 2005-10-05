package Data::Dumper::Names;

use warnings;
use strict;

use Data::Dumper ();
use Scalar::Util 'refaddr';
use PadWalker 'peek_my';
use base 'Exporter';
our @EXPORT = qw/Dumper/;

=head1 NAME

Data::Dumper::Names - Dump variables with names (no source filter)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Dumper::Names;

    my $foo = 3;
    my @bar = qw/this that/;
    warn Dumper($foo, \@bar);
    __END__
    output:
    
    $foo = 3;
    @bar = (
        'this',
        'that'
    );

=head1 EXPORT

Like L<Data::Dumper>, this module automatically exports C<Dumper()>
unless a null import list is explicitly stated.

This module should be considered ALPHA.

=head1 FUNCTIONS

=head2 Dumper

 warn Dumper($foo, \@bar);

C<Dumper> returns a string like C<Dumper> but the variable names are prefixed
for you.  Unlike L<Data::Dumper::Simple>, arrays and hashes must be passed by
reference.

=cut

sub Dumper {
    my $pad = peek_my(1);
    my %pad_vars;
    while (my ($var, $ref) = each %$pad) {
        $var =~ s/^[\$\@\%]/*/;
        $pad_vars{_address($ref)} = $var;
    }
    my @names;
    my $varcount = 1;
    foreach (@_) {
        my $address = _address($_);
        # Naive.  Expects they have no variables named /\$VAR\d+/
        push @names, exists $pad_vars{$address}
          ? $pad_vars{$address}
          : 'VAR' . $varcount++;
    }
    return Data::Dumper->Dump(\@_,\@names);
}

sub _address {
    refaddr $_[0] ? $_[0] : \$_[0];
}

=head1 CAVEATS

=head2 PadWalker

This module is an alternative to L<Data::Dumper::Simple>.  Many people like
the aforementioned module but do not like the fact that it uses a source
filter.  In order to pull off the trick with this module, we use L<PadWalker>.
This introduces its own set of problems, not the least of which is that
L<PadWalker> uses undocumented features of the Perl internals and has an
annoying tendency to break.  Thus, if this module doesn't work on your
machine you may have to go back to L<Data::Dumper::Simple>.

=head2 References

Arrays and hashes, unlike in L<Data::Dumper::Simple>, must be passed by
reference.  Unfortunately, this causes a problem:

 my $foo = \@array;
 warn Dumper( $foo, \@array );

Because of how pads work, there is no easy way to disambiguate between these
two variables.  Thus, C<Dumper> may identify them as C<$foo> or it may
identify them as C<@array>.  If it misidentifies them, it should at least do
so consistently for the individual call to C<Dumper>.  (For Perl 5.8 and
after, subsequent calls to C<Dumper> may have different results in the above
case.  This is because of how Perl handles hash ordering).


=head2 Unknown Variables

The easiest way to have things "just work" is to make sure that you can
see the name of the variable in the C<Dumper> call:

 warn Dumper($foo, \@bar); # good
 warn Dumper($_);          # probably will get output like $VAR1 = ...
 warn Dumper($bar[2]);     # probably will get output like $VAR1 = ...

Usually the output from L<Dumper> will be something like this:

 $foo = 3;
 @bar = (
    'this',
    'that'
 );

However, sometimes a C<$VAR1> or C<$VAR2> will creep in there.  This happens
if pass in anything I<but> a named variable.  For example:

 warn Dumper( $bar[2] ); # $VAR1 = ... can't figure out the name

We probably won't be able to figure out the name of the variable directly
unless we took the time to walk all data structures in scope at the time
C<Dumper> is called.  This is an expensive proposition, so we don't do that.
It's possible we I<will> be able to figure out that name, but only if the
variable was assigned its value from a reference to a named variable.

 $bar[2] = \%foo;
 warn Dumper( $bar[2] );

C<Dumper>, in the above example, will identify that variable as being C<%foo>.
That could be confusing if those lines are far apart.

 foreach ( @customer ) {
    print Dumper( $_ );
 }

It should go without saying that the above will also probably not be able to
name the variables.

=head1 AUTHOR

Curtis, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-dumper-names@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Dumper-Names>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

See L<Data::Dumper> and L<Data::Dumper::Simple>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::Dumper::Names
