#!/usr/bin/env perl
# kickstart.pl - install TXLin and SDL2 on macOS/Linux
# Copyright (C) Tim K/RoverAMD 2018-2019 <timprogrammer@rambler.ru>
# Licensed under MIT License

use Config;
use File::Fetch;

sub fetchWrap {
    my $path = $_[1];
    my $url = $_[0];
    my @cmd = ("curl", "-L", "-o", $path, $url);
    my $statusCode = system(@cmd);
    if ($statusCode == 0) {
        return true;
    } else {
        return false;
    }
}

sub untar {
    my $archive = $_[0];
    my $where = $_[1];
    my @cmd = ('tar', '-C', $where, '--strip-components=1', '-xvzf', $archive);
    if (-d $where) {
        system("rm -r -f \"$where\"") == 0 or return false;
    }
    system("mkdir -p \"$where\"") == 0 or return false;
    if (system(@cmd) == 0) {
        return true;
    } else {
        return false;
    }
}

sub configureSpecificGNUPackage {
    my $dir = $_[0];
    my $prefix = $_[1];
    my $flags = $_[2];
    my $cmd = "cd \"$dir\" && sh configure --prefix=$prefix --disable-shared --enable-static $flags && make -j2 && make install";
    my @final = ("sh", "-c", $cmd);
    return system(@final);
}

sub isMacOS {
    if ($^O == "darwin") {
        return true;
    } else {
        return false;
    }
}

sub isSupported {
    if (isMacOS() || $^O == "linux") {
        return true;
    } else {
        return false;
    }
}

my $version = "1.76b";

print "Welcome to TXLin Installer version $version!\n";
print "Running on $^O, which is ";
if (isSupported()) {
    print "supported, which is really really cool. Meow :-)";
} else {
    print "not supported, unfortunately, the installer will exit now.\n";
    print "Notice that only macOS 10.11 or newer or Ubuntu/SUSE/RedHat Linux are officially supported.\n";
    exit 1;
}

print "\n\n";

system("command -v ruby > /dev/null 2>&1") == 0 or die "Ruby is not installed, cannot continue";
#my $prefix = "/usr/local/txlin/Library/Developer/TXLin";
my $prefix = "/Library/Developer/TXLin";
if (defined $ENV{TXLIN_PREFIX}) {
	$prefix = $ENV{TXLIN_PREFIX};
}

if ($^O == "darwin") {
    #$prefix = "/Library/Developer/TXLin";
    my $versionOS = (split(/ /, $Config{osvers}))[0];
    if ($versionOS < 12) {
        print "I am really sorry, but I had to drop macOS 10.10 and older support due to absence of Metal 2 on these platforms, which is required for TXLin to run and operate. Installation cannot be continued, unfortunately.\n";
        exit 2;
    }
}

print "Everything will be installed into \"$prefix\".\n";
print "\n";

my $sdlVersion = "2.0.10";
my $sdlDir = "https://www.libsdl.org/release/SDL2-$sdlVersion.tar.gz";
my $sdlTTFVersion = "2.0.15";
my $sdlTTFDir = "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-$sdlTTFVersion.tar.gz";
my $freetypeDir = "http://testmakerplusofficial.000webhostapp.com/opensource/freetype-mirror/freetype-2.10.1.tar.gz";
fetchWrap($sdlDir, "/tmp/sdl-tx.tgz") or die "Download failed";
fetchWrap($sdlTTFDir, "/tmp/sdlttf-tx.tgz") or die "Download failed";
fetchWrap($freetypeDir, "/tmp/freetype-tx.tgz") or die "Download failed";
untar("/tmp/sdl-tx.tgz", "/tmp/sdl-tx") or die "Unpack failed";
untar("/tmp/sdlttf-tx.tgz", "/tmp/sdlttf-tx") or die "Unpack failed";
untar("/tmp/freetype-tx.tgz", "/tmp/freetype-tx") or die "Unpack failed";

my $sdlFlags = "--disable-rpath --disable-video-vulkan --disable-video-dummy --disable-3dnow --disable-video-opengl --disable-video-opengles --disable-assembly";
if (isMacOS()) {
    $sdlFlags = "$sdlFlags --disable-video-x11 --enable-video-cocoa --enable-render-metal";
}

print "\nRight now you'll be prompted to enter the admin password to create and maintain the installation prefix.\n";

my $whoami = getlogin();
my $rmCreateDir = "mkdir -v -p \"$prefix\" && chown -v -R $whoami \"$prefix\"";
if (-d $prefix) {
    $rmCreateDir = "rm -r -f -v \"$prefix\" && $rmCreateDir";
}
my @rmCreateDirCmd = ("sudo", "sh", "-c", $rmCreateDir);
system(@rmCreateDirCmd) == 0 or die "Failed.";

configureSpecificGNUPackage("/tmp/sdl-tx", $prefix, $sdlFlags) == 0 or die "SDL2 build failed";

my $freetypeFlags = "--without-fsref --without-fsspec --with-harfbuzz=no --enable-freetype-config --with-png=no --with-bzip2=no --with-zlib=no";
configureSpecificGNUPackage("/tmp/freetype-tx", $prefix, $freetypeFlags) == 0 or die "Freetype2 build failed";

my $sdlTTFFlags = "-with-sdl-prefix=$prefix --with-ft-prefix=$prefix --disable-freetypetest";
configureSpecificGNUPackage("/tmp/sdlttf-tx", $prefix, $sdlTTFFlags) == 0 or die "SDL2 TTF build failed";


my $txlinDir = "https://timkoi.gitlab.io/txlin/files/stable/TXLin.h";
my $txlinFlagsDir = "https://timkoi.gitlab.io/txlin/files/stable/txlin-macflags.rb";
fetchWrap($txlinDir, "$prefix/include/TXLin.h") or die "TXLin itself could not be downloaded";
fetchWrap($txlinFlagsDir, "$prefix/bin/txlin-macflags") or die "TXLin itself could not be downloaded";
chmod(0755, "$prefix/bin/txlin-macflags");

print "\n\n";
print "Installation of TXLin has just been completed!\n";
print "Don't forget to run this command to make txlin-macflags available:\n";
print "\t sudo ln -v -s $prefix/bin/txlin-macflags /usr/local/bin/txlin-macflags\n\nHave fun!";

exit 0;


