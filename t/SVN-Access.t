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

$acl->add_resource('/kanetest', 
    joey => 'rw',
    billy => 'r',
    sam => 'r',
);

$acl->resource('/kanetest')->authorize(
    judy => 'rw',
    phil => 'r',
    frank => '',
    wanda => 'r'
);

$acl->resource('/kanetest')->authorize(sammy => 'r', 2);
$acl->write_acl;

my $test_contents = <<EOF;
[/]
\@folks = rw

[/test]

[/kanetest]
joey = rw
billy = r
sammy = r
sam = r
judy = rw
phil = r
frank = 
wanda = r

[groups]
folks = bob, ed, frank
EOF

my $actual_contents;
open(TEST_ACL, '<', 'svn_access_test.conf');
{
    local $/;
    $actual_contents = <TEST_ACL>;
}

is($actual_contents, $test_contents, "Making sure our output remains in-order.");

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
is(scalar($acl->group('folks')->members), 3, "Checking our group after the write-out.");
$acl->remove_group('folks');
is(defined($acl->groups), '', "Making sure groups is undefined when we delete the last one");

# Jesse Thompson's verify_acl tests
$acl->add_resource('/new', '@doesntexist', 'rw');
eval {
    $acl->write_acl;
};
ok(defined($@), 'We encountered a fatal error when trying to write an erroneous ACL.');
# save future writes the grief
$acl->remove_resource('/new');

# little bit of testing for Matt Smith's new regex.
$acl->add_resource('my-repo:/test/path', 'mikey_g',  'rw');
is($acl->resource('my-repo:/test/path')->authorized->{mikey_g}, 'rw', 'Can we call up perms on the new path?');
$acl->remove_resource('/');
$acl->write_acl;

$acl = SVN::Access->new(acl_file => 'svn_access_test.conf');
$acl->remove_resource('/test');
$acl->remove_resource('my-repo:/test/path');
$acl->remove_resource('/kanetest');

is(defined($acl->resources), '', "Making sure resources is undefined when we delete the last one");
$acl->write_acl;

# the config file should be empty now.. so lets clean up if it is
is((stat('svn_access_test.conf'))[7], 0, "Making sure our SVN ACL file is zero bytes, and unlinking.");
unlink('svn_access_test.conf');
