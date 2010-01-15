package App::NoPAN::Installer;

use strict;
use warnings;

sub new {
    my ($klass, %opts) = @_;
    bless {
        %opts,
    }, $klass;
}

sub shell_exec {
    my ($self, $script) = @_;
    
    print "$script\n";
    system($script) == 0
        or die "error:$script failed with exit status:$?";
}

1;
