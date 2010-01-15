package App::NoPAN::Installer::Perl;

use strict;
use warnings;

use base qw(App::NoPAN::Installer);
use List::Util qw(first);

App::NoPAN->register(__PACKAGE__);

# FIXME use CPAN::Shell

sub can_install {
    my ($klass, $nopan, $root_files) = @_;
    ! ! first { $_ eq 'Makefile.PL' } @$root_files;
}

sub build {
    my ($self, $nopan) = @_;
    $self->shell_exec($_)
        for ("$^X Makefile.PL", "make all", "make test");
}

sub install {
    my ($self, $nopan) = @_;
    $self->shell_exec("make install");
}

1;
