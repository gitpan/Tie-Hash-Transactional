#!/usr/bin/perl -w

my $loaded;

use strict;

BEGIN { $| = 1; print "1..9\n"; }
END { print "not ok 1\n" unless $loaded; }

use Tie::Hash::Transactional;

$loaded=1;
print "ok 1\n";

# Create a T::H::T and populate it
tie my %hash, 'Tie::Hash::Transactional';
%hash=(
	a => 'A',
	b => 'B',
	c => 'C'
);

# Check to see if it stores and fetches correctly :-)
print "not " unless(join('', map { $_.$hash{$_} } sort keys %hash) eq 'aAbBcC');
print "ok 2\n";

$hash{d}='D';

# Check that exists and delete work
print "not " unless(exists($hash{d}) && !exists($hash{e}));
print "ok 3\n";
print "not " unless(delete($hash{d}) && !exists($hash{d}));
print "ok 4\n";

# Save a couple of checkpoints
tied(%hash)->checkpoint();
%hash=(
	x => 'X',
	y => 'Y',
	z => 'Z'
);
tied(%hash)->checkpoint();

# Make sure we're OK after checkpointing ...
print "not " unless(join('', map { $_.$hash{$_} } sort keys %hash) eq 'xXyYzZ');
print "ok 5\n";

# Put some stuff in, make sure it goes in, then rollback ...
$hash{q}='Q';
print "not " unless($hash{q} eq 'Q');
print "ok 6\n";
tied(%hash)->rollback();
print "not " unless(join('', map { $_.$hash{$_} } sort keys %hash) eq 'xXyYzZ');
print "ok 7\n";

# rollback again, to make sure the stack works
tied(%hash)->rollback();
print "not " unless(join('', map { $_.$hash{$_} } sort keys %hash) eq 'aAbBcC');
print "ok 8\n";

# and finally, make sure that rolling back too far really is fatal
eval { tied(%hash)->rollback() };
print "not " unless($@);
print "ok 9\n";
