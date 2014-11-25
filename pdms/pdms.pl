#!/usr/bin/perl 
#===============================================================================
#
#         FILE: pdms.pl
#
#        USAGE: ./pdms.pl  
#
#  DESCRIPTION: 
#
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 06/09/14 11:41:23
#     REVISION: ---
#===============================================================================
use v5.12;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";
use File::Find;
use Data::Printer;
use File::stat;

use autodie;
use Getopt::Long;

use Pdms::SqlManager;

my %params;
$params{path} = q(/mnt/scanner);

GetOptions(\%params,
    "path=s",
    );

#my $db = Pdms::SqlManager->new;
#$db->connect;

say $params{path}." not found" and exit unless -d $params{path};

opendir(my $fdh, $params{path});
while(my $fdir = readdir($fdh)) {
    next if $fdir =~ /\A\.\.?/;

    say $fdir;
    my $sta = stat($fdir);
    p $sta;
    print_dir($fdir) if -d $fdir;
}
closedir($fdh);

sub print_dir {
    my $dir = shift;

    return unless -d $dir;

    opendir(my $dh, $dir);
    while(my $item = readdir($dh)) {
        next if $item =~ /\A\.\.?/;
        say $item;

        my @stat = stat($item);
        p @stat;
        print_dir($item) if -d $item;
    }
    closedir($dh);
}
__END__
my $wanted = sub {
    my $full_name = $File::Find::name;
    say "check $full_name";
    return if -d $full_name;
    #return unless /\.(pdf|tiff|jpe?g|tif)/i;

    say "$full_name found";
};

find($wanted, $params{path});
