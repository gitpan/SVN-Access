package SVN::Access;

use SVN::Access::Group;
use SVN::Access::Resource;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my ($class, %attr) = @_;
    my $self = bless(\%attr, $class);
    
    # it's important that we have this.
    die "No ACL file specified!" unless $attr{acl_file};

    if (-e $attr{acl_file}) {
        # parse the file in.
        $self->parse_acl;
    } else {
        # empty acl.
        $attr{acl} = {};
    }
    return $self;
}

sub parse_acl {
    my ($self) = @_;
    open(ACL, '<', $self->{acl_file}) or die "Can't open SVN Access file " . $self->{acl_file} . ": $!";
    my $current_resource;
    while (my $line = <ACL>) {
        # ignore comments
        next if $line =~ /^#/;
        next if $line =~ /^[\s\r\n]+$/;
        if ($line =~ /^\[\s*(.+?)\s*\][\r\n]+$/) {
            # this line is defining a new resource.
            $current_resource = $1;
            unless ($current_resource eq "groups") {
                $self->add_resource($current_resource);
            }
        } else {
            # both groups and resources need this parsed.
            my ($k, $v) = $line =~ /^(.+?)\s*=\s*(.*)[\r\n]+$/;

            if ($current_resource eq "groups") {
                # this is a group
                $self->add_group($k, split(/\s*,\s*/, $v));
            } else {
                # this is a generic resource
                if (my $resource = $self->resource($current_resource)) {
                    $resource->authorize($k => $v);
                } else {
                    $self->add_resource($current_resource, $k, $v);
                }
            }
        }
    }
    close (ACL);
}

sub write_acl {
    my ($self) = @_;
    open (ACL, '>', $self->{acl_file}) or warn "Can't open ACL file " . $self->{acl_file} . " for writing: $!\n";
    foreach my $resource ($self->resources) {
        if (defined($resource) && $resource->authorized) {
            print ACL "[" . $resource->name . "]\n";
            while (my ($k, $v) = (each %{$resource->authorized})) {
                print ACL "$k = $v\n";
            }
            print ACL "\n";
        }
    }
    if ($self->groups) {
        print ACL "[groups]\n";
        foreach my $group ($self->groups) {
            print ACL $group->name . " = " . join(', ', $group->members) . "\n";
        }
    }
    close(ACL);
}

sub write_pretty {
    my ($self) = @_;

    my $max_len = 0;

    # Compile a list of names that will appear on the left side
    my @names;
    if ($self->groups) {
        for ($self->groups) {
            push(@names, $_->name);
        }
    }
    if ($self->resources) {
        for ($self->resources) {
            push(@names, keys(%{$_->authorized}));
        }
    }

    # Go through that list looking for the longest name
    for (@names) {
        $max_len = length($_) >= $max_len ? length($_) : $max_len;
    }

    open (ACL, '>', $self->{acl_file}) or warn "Can't open ACL file " . $self->{acl_file} . " for writing: $!\n";
    foreach my $resource ($self->resources) {
        if (defined($resource) && $resource->authorized) {
            print ACL "[" . $resource->name . "]\n";
            while (my ($k, $v) = (each %{$resource->authorized})) {
                print ACL "$k" . " " x ($max_len - length($k)) . " = $v\n";
            }
            print ACL "\n";
        }
    }
    if ($self->groups) {
        print ACL "[groups]\n";
        foreach my $group ($self->groups) {
            print ACL $group->name . " " x ($max_len - length($group->name)) . " = " . join(', ', $group->members) . "\n";
        }
    }
    close(ACL);
}

sub add_resource {
    my ($self, $resource_name, %access) = @_;
    if ($self->resource($resource_name)) {
        die "Can't add new resource $resource_name: resource already exists!\n";
    } elsif ($resource_name !~ /^\w*\:*\//) {
        die "Invalid resource format in $resource_name! (format 'repo:/path')!\n";
    } else {
        my $resource = SVN::Access::Resource->new(
            name        =>      $resource_name,
            authorized  =>      \%access,
        );
        push(@{$self->{acl}->{resources}}, $resource);
        return $resource;
    }
}

sub remove_resource {
    my ($self, $resource_name) = @_;
    my @resources;
    foreach my $resource ($self->resources) {
        push(@resources, $resource) unless $resource->name eq $resource_name;
    }
    $self->{acl}->{resources} = scalar(@resources) ? \@resources : undef;
}

sub resources {
    my ($self) = @_;
    if (ref($self->{acl}->{resources}) eq "ARRAY") {
        return (@{$self->{acl}->{resources}});
    } else {
        return (undef);
    }
}

sub resource {
    my ($self, $resource_name) = @_;
    foreach my $resource ($self->resources) {
        return $resource if defined($resource) && $resource->name eq $resource_name;
    }
    return undef;
}

sub add_group {
    my ($self, $group_name, @initial_members) = @_;

    # get rid of the @ symbol.
    $group_name =~ s/\@//g;

    if ($self->group($group_name)) {
        die "Can't add new group $group_name: group already exists!\n";
    } else {
        my $group = SVN::Access::Group->new(
            name        =>      $group_name,
            members     =>      \@initial_members,
        );
        push(@{$self->{acl}->{groups}}, $group);
        return $group;
    }
}

sub remove_group {
    my ($self, $group_name) = @_;
    my @groups;

    # get rid of the @ symbol.
    $group_name =~ s/\@//g;
    foreach my $group ($self->groups) {
        push(@groups, $group) unless $group->name eq $group_name;
    }

    $self->{acl}->{groups} = scalar(@groups) ? \@groups : undef;
}

sub groups {
    my ($self) = @_;
    if (ref($self->{acl}->{groups}) eq "ARRAY") {
        return (@{$self->{acl}->{groups}});
    } else {
        return (undef);
    }
}

sub group {
    my ($self, $group_name) = @_;
    foreach my $group ($self->groups) {
        return $group if defined($group) && $group->name eq $group_name;
    }
    return undef;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SVN::Access - Perl extension to manipulate SVN Access files

=head1 SYNOPSIS

  use SVN::Access;
  my $acl = SVN::Access->new(acl_file   =>  '/usr/local/svn/conf/my_first_dot_com.conf');

  # add a group to the config
  $acl->add_group(
      name      =>      'stooges',
      members   =>      [qw/larry curly moe shemp/],
  );

  # write out the acl (thanks Gil)
  $acl->write_acl;

  # give the stooges commit access to the production version of 
  # our prized intellectual property, the free car giver-awayer.. 
  # (thats how we get users to the site.)
  $acl->add_resource(
      name       => '/free_car_giver_awayer/branches/prod_1.21-sammy_hagar',
      authorized => {
          '@stooges' => 'rw',
      }
  );

  $acl->write_pretty; # with the equals signs all lined up.

=head1 DESCRIPTION

B<SVN::Access> includes both an object oriented interface for manipulating 
SVN access files (AuthzSVNAccessFile files), as well as a command line 
interface to that object oriented programming interface (B<svnaclmgr.pl>).

Gil Hicks has a much better description of this module...

B<Definitely a jackhammer, I'm in there with some pressure and when I'm done, you're not the same as before. 
You're changed.>

=head1 METHODS

=over 4

=item B<new>

the constructor, takes key / value pairs.  only one is required.. in fact 
only one is used right now.  acl_file.

Example:
  my $acl = SVN::Access->new(acl_file   =>  '/path/to/my/acl.conf');

=item B<add_resource>

adds a resource to the current acl object structure.  note: the changes 
are only to the object structure in memory, and one must call the B<write_acl>
method, or the B<write_pretty> method to commit them.

Example:
  $acl->add_resource('/',
    rick    =>  'rw',
    steve   =>  'rw',
    gibb    =>  'r',
  );

=item B<remove_resource>

removes a resource from the current acl object structure.  as with B<add_resource>
these changes are only to the object structure in memory, and must be commited 
with a write_ method.

Example:
  $acl->remove_resource('/');

=item B<resources>

returns an array of resource objects, takes no arguments.

Example:
  for($acl->resources) {
      print $_->name . "\n";
  }

=item B<resource>

resolves a resource name to its B<SVN::Access::Resource> object.

Example:
  my $resource = $acl->resource('/');

=item B<add_group>

adds a group to the current acl object structure.  these changes are 
only to the object structure in memory, and must be written out with 
B<write_acl> or B<write_pretty>.

Example:
  $acl->add_group('stooges', 'larry', 'curly', 'moe', 'shemp');

=item B<remove_group>

removes a group from the current acl object structure.  these changes
are only to the object structure in memory, and must be written out 
with B<write_acl> or B<write_pretty>.

Example:
  $acl->remove_group('stooges');

=item B<groups>

returns an array of group objects, takes no arguments.

Example:
  for($acl->groups) {
      print $_->name . "\n";
  }

=item B<group>

resolves a group name to its B<SVN::Access::Group> object.

Example:
  $acl->group('pants_wearers')->add_member('ralph');

=item B<write_acl>

takes no arguments, writes out the current acl object structure to 
the acl_file specified in the constructor.

Example:
  $acl->write_acl;

=item B<write_pretty>

the same as write_acl, but does it with extra whitespace to line 
things up.

Example:
  $acl->write_pretty;

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
