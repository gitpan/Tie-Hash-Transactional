package Tie::Hash::Transactional;

use strict;

my $VERSION='1.0';

sub TIEHASH {
	my $class = shift;
	my $self = {
		STACK		=> [],
		CURRENT_STATE	=> {},
	};
	
	return bless $self, $class;
}

sub checkpoint {
	my $self = shift;
	# make a new copy of CURRENT_STATE before putting on stack,
	# otherwise CURRENT_STATE and top-of-STACK will reference the
	# same data structure, which would be a Bad Thing
	my %hash_for_stack = %{$self->{CURRENT_STATE}};
	push @{$self->{STACK}}, \%hash_for_stack;
}

sub commit {
	my $self = shift;
	$self->{STACK}=[];                     # clear all checkpoints
}

sub rollback {
	my $self = shift;
	die("Attempt to rollback too far") unless(scalar @{$self->{STACK}});
	# no copying required, just update a pointer
	$self->{CURRENT_STATE}=pop @{$self->{STACK}};
}

sub CLEAR {
	my $self=shift;
	$self->{CURRENT_STATE}={};
}

sub STORE {
        my($self, $key, $value)=@_;
        $self->{CURRENT_STATE}->{$key}=$value;
}

sub FETCH {
	my($self, $key) = @_;
	$self->{CURRENT_STATE}->{$key};
}

sub FIRSTKEY {
	my $self = shift;
	scalar keys %{$self->{CURRENT_STATE}};
	scalar each %{$self->{CURRENT_STATE}};
}

sub NEXTKEY { my $self = shift; scalar each %{$self->{CURRENT_STATE}}; }
sub DELETE { my($self, $key) = @_; delete $self->{CURRENT_STATE}->{$key}; }
sub EXISTS { my($self, $key) = @_; exists($self->{CURRENT_STATE}->{$key}); }

1;
__END__

=head1 NAME

Tie::Hash::Transactional - A hash with checkpoints and rollbacks

=head1 SYNOPSIS

  use Tie::Hash::Transactional

  tie my %transact_hash, 'Tie::Hash::Transactional';
  %transact_hash = (
    good => 'perl',
    bad  => 'java',
    ugly => 'tcl'
  );

  tied(%transact_hash)->checkpoint();
  $transact_hash{indifferent} = 'C';

  # hmmm ... must avoid controversial sample code, so ...
  tied(%transact_hash)->rollback();

=head1 DESCRIPTION

This module implements a hash with RDBMS-like transactions.  You can
checkpoint the hash (that is, you can save its current state), and you
can rollback the hash (restore it to the previous saved state).  You
can checkpoint and rollback multiple times, as checkpointed states are
saved on a stack.

The following named parameters are supported:

=over 4

=item C<(none)>

Currently, no named parameters are supported.  It is intended that
future versions will use named parameters to let you apply this
transactional grooviness to other tied hashes.

=back

=head1 METHODS

The following methods are available.  Call them thus:

C<tied(%my_hash)-E<gt>methodname();>

=over 4

=item C<checkpoint>

Saves the current state of the hash onto the stack, so that it can be
retrieved later.

=item C<commit>

Discards all saved states from the stack.  Why bother?  Well, if your
transactional hash contains a lot of data, then if you have a load of
checkpoints on the stack, then it's going to consume a vast amount of
memory - each state on the stack is just a copy of the hash as it was
when you checkpointed.  Once you are sure that your hash contains the
data you want it to contain, and you no longer need any of the previous
states, you can free a lot of memory of commiting.

In a future version, which is intended to add support for making other
types of tied hashes transactional, this method may do things too.

=item C<rollback>

Retrieve the last saved state from the stack.  Any changes you have
made since the last checkpoint are discarded.  It is a fatal error
to rollback with nothing on the stack.

=back

=head1 BUGS

Plenty, no doubt.  Please tell me if you find any.

=head1 AUTHOR

David Cantrell <david@cantrell.org.uk>

=head1 COPYRIGHT

Copyright 2001 David Cantrell.

This module is licensed under the same terms as perl itself.

=head1 SEE ALSO

Tie::Hash(3)

=cut
