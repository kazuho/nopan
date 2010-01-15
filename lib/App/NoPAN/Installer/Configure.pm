package App::NoPAN::Installer::Configure;

use strict;
use warnings;

use base qw(App::NoPAN::Installer);
use List::Util qw(first);

App::NoPAN->register(__PACKAGE__);

# FIXME use CPAN::Shell

sub can_install {
    my ($klass, $nopan, $root_files) = @_;
    ! ! first { $_ =~ /^configure(\.ac|\.in|)$/ } @$root_files;
}

sub build {
    my ($self, $nopan) = @_;
    $self->shell_exec('autoreconf -i')
        unless -e 'configure';
    $self->shell_exec($_)
        for ("./configure", "make all");
}

sub install {
    my ($self, $nopan) = @_;
    $self->shell_exec("make install");
}

1;
