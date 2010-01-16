use strict;
use warnings;

use Cwd;
use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use Test::More;

$| = 1;

use_ok('App::NoPAN');

my $tempdir = tempdir(CLEANUP => 1);

# test build
unless (my $pid = fork) {
    die "fork failed:$!"
        unless defined $pid;
    # child process
    open my $fh, '>', "$tempdir/build.log"
        or die "failed to open temporary file:$tempdir/build.log:$!";
    open STDOUT, '>&', $fh
        or die "failed to redirect STDOUT:$!";
    open STDERR, '>&', $fh,
        or die "failed to redirect STDERR:$!";
    close $fh;
    exec(
        qw(blib/script/nopan --no-install),
        "file://@{[getcwd]}/t.assets/perl/",
    );
    die "could not exec nopan:$!";
}
while (wait == -1) {}
my $exit_status = $?;

print STDERR "nopan exitted with status:$@\n", read_file("$tempdir/build.log")
    if $exit_status;
is $exit_status, 0, "build and test";

done_testing;
