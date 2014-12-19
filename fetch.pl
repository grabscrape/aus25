#!/bin/perl

use v5.10;

use File::Fetch;
use File::Basename;
use English;
use Data::Dumper;
use strict;

my $cache_dir = './Cache/';

my $root = 'http://www.ava.com.au';
my $uri  = $root . '/equine/find-an-equine-vet';
my @files;
say $uri;
say;


my $dir = $cache_dir . basename( $uri );
say $dir;
mkdir $dir;


my @links0 = extract_hrefs( $uri, $dir  );
say Dumper \@links0;
#exit 0;

say;
say 'second phase';
say;
say;

foreach my $l0 ( @links0 ) {
    say;

    my $d0 = $dir . '/' . basename( $l0 );
    $l0 = $root . $l0;
    say "\tD0: ", $d0, ' : ', $l0;
    mkdir $d0;
    my @links1 = extract_hrefs( $l0, $d0  );


    foreach my $l1 ( @links1 ) {
        say;

        my $d1 = $d0 . '/' . basename( $l1 );
        if( $l1 !~ m#/equine/# ) {
            $l1 = '/equine/'.$l1;
        }
        $l1 = $root . $l1;
        say "\tLOOK D1: ", $d1, ' : ', $l1;
        mkdir $d1;
        my @links2 = extract_hrefs( $l1, $d1  );
        say Dumper \@links2;
    }
}


exit 0;

##
## Subs
##
sub extract_hrefs {
    my $uri = shift;
    #$uri = '/equine/'.$uri unless $uri =~ m/^\/equine/;
    my $dir = shift;

say 'Got dir ', $dir, '   URI: '. $uri;
    my @hrefs_array;

    my $ff = File::Fetch->new( uri => $uri );
    say 'File: ', $ff->file;
    my $grabbed_file = $dir . '/../' . $ff->file . '.html';
    say 'Grabbed file: ', $grabbed_file;
    unless ( -f $grabbed_file  and -s $grabbed_file != 0 ) {
        say "Start to fetch $grabbed_file";
        my $where = $ff->fetch( to => $dir ); 
        say 'Where: ', $where;
        rename $where, $grabbed_file;
    }
    @hrefs_array = hrefs( $grabbed_file );
    undef $ff;
    return @hrefs_array;
}


sub hrefs {
    my $f = shift;
    my $data;
    open FD, $f or die "Can't read file 'filename' [$!]\n";
    $data .= $_ for <FD>;
    close FD;

    my @hrefs; 
    while( $data =~ m/<area.*?\shref="(.\S+)"/ ) {
        #say $1;
        push @hrefs, $1;
        $data = $POSTMATCH;
    }
    return @hrefs;
}

