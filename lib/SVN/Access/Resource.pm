package SVN::Access::Resource;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class, %attr) = @_;
    return bless(\%attr, $class);
}

sub authorized {
    my ($self) = @_;
    if (ref ($self->{authorized}) eq "HASH") {
        return $self->{authorized};
    }
    return undef;
}

sub authorize {
    my ($self, $entity, $access) = @_;
    $self->{authorized}->{$entity} = $access;
}

sub deauthorize {
    my ($self, $entity) = @_;
    delete ($self->{authorized}->{$entity}) if ref($self->{authorized});
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SVN::Access::Resource - Object representing a SVN Access file group!

=head1 SYNOPSIS

  use SVN::Access;

  my $acl = SVN::Access->new(acl_file => '/usr/local/svn/conf/badnews_svn_access.conf');

  # grant mikey_g read-write access to /
  $acl->resource('/')->authorize('mikey_g', rw);

  # print out users and their authorization for /
  while (my ($user, $perms) = each(%{$acl->resource('/')->authorized})) {
      print "$user: $perms\n";    
  }

  # revoke access for mikey_g to /
  $acl->resource->('/')->deauthorize('mikey_g');

=head1 DESCRIPTION

B<SVN::Access::Resource> is an object wrapper around a SVN::Access resource.

=head1 METHODS

=over 2

=item 
B<new>
constructor, the most basic kind, i'm only looking for authorized (hashref), and 
name.

Example:
  my $resource = SVN::Access::Resource->new(
      name => '/',
      authorized => {
          rick => 'rw', # commit access..
          randal => 'r', # read only access
          luthor => '', # explicitly deny access
      }
  );

=item
B<authorized>
returns a hash reference containing (user, access) pairs.

Example:
  my %authorized = %{$resource->authorized};

=item
B<authorize>
authorizes a user / group for access to this resource.

Example:
  $resource->authorize('@admins' => 'rw'); # give the admins commit
  $resource->authorize('*', => 'r'); # give anonymous read only

=item
B<deauthorize>
revokes the user / group's access to this resource.

Example:
  $resource->deauthorize('rick'); # later, rick.

=item
B<name>
accessor method that returns the resource's name (path)

=back

=head1 SEE ALSO

subversion (http://subversion.tigris.org/), SVN::ACL, svnserve.conf

=head1 AUTHOR

Michael Gregorowicz, E<lt>mike@mg2.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Michael Gregorowicz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

