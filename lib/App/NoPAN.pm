package App::NoPAN;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
use Cwd;
use File::Temp qw(tempdir);
use HTML::LinkExtor;
use List::Util qw(first);
use LWP::Simple ();
use Scope::Guard;

# FIXME find and automatically load NoPAN::Installer::*.pm
require App::NoPAN::Installer::Perl;
require App::NoPAN::Installer::Configure;
require App::NoPAN::Installer::Makefile; # should better be the last

my %Defaults = (
    no_install => undef,
);
my @Installers;

__PACKAGE__->mk_accessors(keys %Defaults);

sub new {
    my ($klass, %opts) = @_;
    bless {
        %Defaults,
        %opts,
    }, $klass;
}

sub install {
    my ($self, $url) = @_;
    
    die "invalid URL:$url"
        unless $url =~ m{^[a-z]+://};
    
    $url .= '/'
        unless $url =~ m|/$|;
    warn "downloading files from URL:$url\n";
    my @root_files = $self->files_from_dir($url);
    
    my $installer = first { $_->can_install($self, \@root_files) } @Installers
        or die "do not know how to install:$url";
    
    my $workdir = tempdir(CLEANUP => 1);
    $self->fetch_all($url, $workdir, '', \@root_files);
    
    {
        my $pwd = getcwd;
        my $popdir = Scope::Guard->new(sub { chdir $pwd });
        chdir $workdir
            or die "failed to change directory to:$workdir:$!";
        $installer->build($self);
        $installer->install($self)
            unless $self->no_install;
    }
}

sub fetch_all {
    my ($self, $base_url, $dir, $subdir, $files, $fetched) = @_;
    $fetched ||= {};
    for my $f (@$files) {
        if ($f =~ m|/$|) {
            my $d = $`;
            mkdir "$dir/$subdir$d"
                or die "failed to create dir:$dir/$subdir$d:$!";
            $self->fetch_all(
                $base_url,
                $dir,
                "$subdir$f",
                [ $self->files_from_dir("$base_url$subdir$f") ],
                $fetched,
            );
        } elsif (! $fetched->{"$subdir$f"}) {
            print "$subdir$f\n";
            my $r = LWP::Simple::mirror("$base_url$subdir$f", "$dir/$subdir$f");
            die "failed to fetch URL:$base_url$subdir$f, got $r"
                unless $r == 200;
            $fetched->{"$subdir$f"} = 1;
        }
    }
}

sub files_from_dir {
    my ($self, $url) = @_;
    
    my $body = LWP::Simple::get($url)
        or die "failed to fetch URL:$url";
    return grep {
        $_ !~ m{^(\.{1,2}|)$},
    } map {
        $_ =~ /^$url/ ? ($') : ()
    } map {
        my ($tag, %attr) = @$_;
        $tag eq 'a' && $attr{href} ? ($attr{href}) : ();
    } do {
        my $lx = HTML::LinkExtor->new(undef, $url);
        $lx->parse($body);
        $lx->links;
    };
}

sub register {
    my ($klass, $installer) = @_;
    push @Installers, $installer;
}

1;
