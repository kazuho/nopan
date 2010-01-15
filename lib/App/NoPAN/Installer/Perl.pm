package App::NoPAN::Installer::Perl;

use strict;
use warnings;

use base qw(App::NoPAN::Installer);
use List::Util qw(first);
use Config;

App::NoPAN->register(__PACKAGE__);

# FIXME use CPAN::Shell

sub can_install {
    my ($klass, $nopan, $root_files) = @_;
    ! ! first { $_ eq 'Makefile.PL' } @$root_files;
}

sub build {
    my ($self, $nopan) = @_;
    $self->shell_exec($_)
        for ("$^X Makefile.PL", "$Config{make} all");
}

sub test {
    my ($self, $nopan) = @_;
    $self->shell_exec("$Config{make} test")
        unless defined $nopan->opt_test && $nopan->opt_test == 0;
}

sub install {
    my ($self, $nopan) = @_;
    $self->shell_exec("$Config{make} install");
}

1;
