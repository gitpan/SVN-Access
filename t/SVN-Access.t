# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Access.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 1;
use Test::More qw(no_plan); # replace this later.

BEGIN { use_ok('SVN::Access') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# create a new file.
my $acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
$acl->add_group('@folks', 'bob', 'ed', 'frank');

is(scalar($acl->group('folks')->members), 3, "Added new group to the object.");
$acl->add_resource('/', '@folks', 'rw');
is($acl->resource('/')->authorized->{'@folks'}, 'rw', "Make sure we added these folks to the '/' resource.");
$acl->write_acl;

$acl->add_resource('/test');
is(ref($acl->resource('/test')), 'SVN::Access::Resource', "Do empty resources show up in the array?");
$acl->write_acl;

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
is(ref($acl->resource('/test')), 'SVN::Access::Resource', "Do empty resources show up in the array after re-parsing the file?");

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
is(scalar($acl->group('folks')->members), 3, "Checking our group after the write-out.");
$acl->remove_group('folks');
is(defined($acl->groups), '', "Making sure groups is undefined when we delete the last one");
$acl->write_acl;

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
$acl->remove_resource('/');
$acl->remove_resource('/test');
is(defined($acl->resources), '', "Making sure resources is undefined when we delete the last one");
$acl->write_acl;

# the config file should be empty now.. so lets clean up if it is
is((stat('svn_access_test.conf'))[7], 0, "Making sure our SVN ACL file is zero bytes, and unlinking.");
unlink('svn_access_test.conf');
