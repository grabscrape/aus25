#!/usr/bin/perl


use v5.10;
use Data::Dumper;
use Data::Printer;

## http://habrahabr.ru/post/227493/
use Mojo::DOM;

use Encode;
use utf8;
use strict;
my $output = `find ./Result -type f`;

my @data = ();
foreach my $line (split /\n/, $output ) {
    #say $line;
    #$line = decode('utf8',$line);
    # ./Result/find-a-vet-qld-sunshinecoast.html
    if( $line =~ m/.*find-a-vet-(\w+)-(\w+).html/ ) {
        #say $1, ':', $2;
        push @data, parse( $line, {State=>$1, Region=>$2} );
        #last;
    }
}

#say p @data;

my @data2;
foreach my $e ( @data ) {
    my $email = $e->{Email};
    #say $email;

    $email =~ s/^\s*S//;
    $email =~ s/\s*$//; #(\S.*\S)\s*$/$1/g;

    $email =~ s/\s+\[at\]\s+/@/g;
    $email =~ s/\s+\[dot\]\s+/./g;

    $email =~ s/\s+@/@/g;         ####  aggavet @waggavet.com.au

#    say $email;
#next;
    my @parts = split /\s+/, $email;

    if( @parts > 1 ) {
        my @emails = ();
        my @webs = ();
        foreach my $e0 (@parts) {
            next if $e0 eq 'or';
            if( $e0 =~ m/@/ ) {
                push @emails, $e0;
            } else {
                push @webs, $e0;
            }
        }

        #say "\t$email";
        if( $e->{Website} ne '' and @webs ) {
            say ':', $e->{Website}, ':';
            die 'not empty web' ;
        }
        #say "\tEM:", join ',', @emails;
        #say "\tWEB:", join ',', @webs;

        $e->{Email} = join ', ', @emails;
        $e->{Website} = join ', ', @webs if @webs;
    } else {
        $e->{Email} = $email;
    }
    #say $e->{Email};



    my $address = $e->{'**address'};
    #say $address;


    my $Region = ucfirst $e->{Region};
    $e->{Region} = $Region;

    my $State = uc $e->{State};
    $e->{State} = $State;


    $address =~ s/,?\s*${State}\b//g;

    if( $address =~ m/\D(\d+)$/ ) {
        $e->{Postcode} = $1;
        $address =~ s/,?\s*\d+$//;
    }

    #say $e->{State}, ':', $address, "\t\t", $e->{Postcode};
#    say "\t$address";
   
    my( $al1, $al2, @al3 ) = split /,\s*/, $address;
#say 'Al1:', $al1, ' Al2:', $al2, ' Itog:', join '::', @al3;

    $e->{AddrLine1} = $al1;
    $e->{AddrLine2} = $al2;
    $e->{AddrLine3} = join ', ', @al3;
    #printf '%7d %s'."\n", $e->{postcode} || '', $e->{address};


    # $e->{'**address'} = $address;

###

    #say $e->{contact}; 
    my @contacts = split/\s*(,|and)\s*/, $e->{contact};
    my @rc;
    if( @contacts > 1 ) {
        foreach my $c ( grep $_ !~ m/^(,|and)$/,  @contacts ) {
            #say "\t$c";
            push @rc, {contact=>$c};
        }
    } else {
        push @rc, {contact=>$e->{contact}};
    }

    foreach my $c ( @rc ) {
        #say "\t", ">$c->{contact}<:";
        if( $c->{contact} =~ 
                m/^((Dr\s+)?\S+)\s+(\S.*)$/i ) {
            my $forename = $1;
            my $surname = $3;
        #    say "\t\t", $forename, ':', $surname;
            $c->{forename} = $forename;
            $c->{surname} = $surname;
        } elsif( $c->{contact} eq '' ) {
            $c->{forename} = '';
            $c->{surname} = '';
        } else {
            $c->{forename} = $c->{contact};
            $c->{surname} = $c->{contact};
        #    say "******************: ", $c->{contact};
        }
    }
   
    if( @rc == 1 ) {  
        #delete $e->{contact};
        $e->{Forename} = $rc[0]->{forename};
        $e->{Surname} = $rc[0]->{surname};
        push @data2, $e; 
    } else {
        foreach my $c ( @rc ) {
            my %e1 = %$e;
            $e1{Forename} = $c->{forename};
            $e1{Surname} = $c->{surname};
            $e1{Added} = '**************************';
            push @data2, \%e1; 
        }
    }
}

my @list = qw/Institution
              Services
              Forename
              Surname
              State
              Region
              AddrLine1
              AddrLine2
              AddrLine3
              **address
              Postcode
              Phone
              Email
              Website /;

open CSV, ">Result/sheet.csv";
say CSV join '|', @list;
foreach my $d (@data2) {
    say CSV join '|', map {
        $d->{$_}
    } @list;
}
close CSV;

my $o=`./csv2excel.py --sep '|' --title --output ./Result/sheet.xls ./Result/sheet.csv`;
say "Py output: $o" if $o;

#foreach my $i ( qw/
#say Dumper \@data2;


#####
sub parse {
    my $file = shift;
    my $pre_data = shift;

    my $body;
    open FD, $file or die "Error: $!";
    $body .= $_ for <FD>;
    close FD;
    $body = decode('utf8',$body);
 
    my $dom = Mojo::DOM->new( $body );
    my $table_collection = $dom->find('table');

    my @data;
    #my $data = {}; #\%{ $pre_data }; 
    foreach my $t ( $table_collection->each ) {
        my $data = { %$pre_data };
        #$data = \%{ $pre_data }; 
        my $title = $t->previous->text;
        #say 'A:', $title;
        $data->{'Institution'} = $title;
        #say "T: $t";
        my $tr_collection = $t->find('tr');
        foreach my $tr ( $tr_collection->each ) {
            my $key = $tr->find('td')->[0];
            if( $key )  {
                $key = $key->all_text; #->node; 
            } else {
                #say $tr;
            }
            my $value = $tr->find('td')->[1];
            if( $value ) {
                $value = $value->all_text; #->text;
            } else {
                #say $tr;
            }

            if(       $key =~ m/Services/ ) {
                $data->{Services} = $value;
            } elsif ( $key =~ m/Contact/ ) {
                $data->{contact} = $value;
            } elsif ( $key =~ m/Address/ ) {
                $data->{'**address'} = $value;
            } elsif ( $key =~ m/Phone/ ) {
                $data->{Phone} = $value;
            } elsif ( $key =~ m/Emai/ ) {
                $data->{Email} = $value;
            } elsif ( $key =~ m/Website/ ) {
                $data->{Website} = $value;
            } else {
              #  say "key: $key";
              #  say "value: $value";
            } 
        }
        push  @data, $data;
    } 
    return @data;
    
}

