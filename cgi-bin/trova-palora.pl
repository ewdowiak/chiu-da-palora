#!/usr/bin/env perl

##  "trova-palora.pl" -- queries samples index
##  Copyright (C) 2020 Eryk Wdowiak
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##  
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <https://www.gnu.org/licenses/>.

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  

use strict;
use warnings;
use CGI qw(:standard);
use Storable qw( retrieve ) ;
{   no warnings;             
    ## $Storable::Deparse = 1;  
    $Storable::Eval    = 1;  
}

##  storables
my $samples_idx = '../cgi-lib/samples-index';
my $vocab_notes = '../cgi-lib/vocab-notes';
my $verb_tools  = '../cgi-lib/verb-tools';

##  config
my $topnav_html = '../config/topnav.html';
my $navbar_html = '../config/navbar-footer.html';

##  example to offer
my $example;
$example .= '<p style="margin-top: 0.5em; margin-bottom: 0.25em;"><i>pi esempiu:</i></p>'."\n";
$example .= '<ul style="margin-top: 0.25em;">' ."\n";
$example .= '<li><a href="/cgi-bin/trova-palora.pl?palori=mari"><span class="code">mari</span></a></li>'."\n";
$example .= '<li><a href="/cgi-bin/trova-palora.pl?palori=acqua%20fimmini%20e%20focu"><span class="code">acqua '."\n";
$example .= ' fimmini e focu</span></a></li>' ."\n";
$example .= '</ul>' ."\n";

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  SETUP
##  =====

##  retrieve authors, words and subroutines
my $sm_ref  = retrieve( $samples_idx );
my %smword  = %{ $sm_ref->{smword} };
my %smauth  = %{ $sm_ref->{smauth} };
my %smtitle = %{ $sm_ref->{smtitle} };
my %smsubs  = %{ $sm_ref->{smsubs} };

##  what are we looking for?
my $in_palori = ( ! defined param('palori') ) ? "" : param('palori');
my $in_autori = ( ! defined param('autori') ) ? "" : param('autori');
my $in_titulu = ( ! defined param('titulu') ) ? "" : param('titulu');

##  remove accents, make lower case
my $palori_str = lc( $smsubs{strip_line}( $in_palori , \%smsubs ));
my $autori_str = lc( $smsubs{strip_line}( $in_autori , \%smsubs ));
my $titulu_str = lc( $smsubs{strip_line}( $in_titulu , \%smsubs ));

##  remove parenthesis and excess spaces
$palori_str =~ s/[\(\)]//g;  $autori_str =~ s/[\(\)]//g;  $titulu_str =~ s/[\(\)]//g;
$palori_str =~ s/\s+/ /g;    $autori_str =~ s/\s+/ /g;    $titulu_str =~ s/\s+/ /g;
$palori_str =~ s/"//g;       $autori_str =~ s/"//g;       $titulu_str =~ s/"//g;
$palori_str =~ s/,//g;       $autori_str =~ s/,//g;       $titulu_str =~ s/,//g;
$palori_str =~ s/^ //;       $autori_str =~ s/^ //;       $titulu_str =~ s/^ //;
$palori_str =~ s/ $//;       $autori_str =~ s/ $//;       $titulu_str =~ s/ $//;

##  enforce max length, without any generosity
$palori_str = substr( $palori_str , 0 , 48 );  ## (48 is form limit)
$titulu_str = substr( $titulu_str , 0 , 48 );  ## (48 is form limit)
$autori_str = substr( $autori_str , 0 , 24 );  ## (24 is form limit)

##  header, form and footer
my $html_head = mk_header($topnav_html, $palori_str , $autori_str , $titulu_str );
my $html_form = mk_form( $palori_str , $autori_str , $titulu_str );
my $html_foot = mk_footer($navbar_html);

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  FIND MATCHES
##  ==== =======

##  what to search for
my @palori_sch;
my @autori_sch;
my @titulu_sch;

##  split word search string at space and push if four or more characters
my @palori_array = split( ' ', $palori_str );
foreach my $palora (@palori_array) {
    if ( length($palora) >= 4 ) {
	push( @palori_sch , $palora );
    }
}

##  split author search string at space and push if four or more characters
$autori_str =~ s/(la )?mattina/la~mattina/g;
$autori_str =~ s/(di )?marco/di~marco/g;
$autori_str =~ s/(de )?vita/de~vita/g;

my @autori_array = split( ' ', $autori_str );
s/la~mattina/la mattina/g for @autori_array;
s/di~marco/di marco/g for @autori_array;
s/de~vita/de vita/g for @autori_array;

foreach my $author (@autori_array) {
    if ( length($author) >= 4 ) {
	push( @autori_sch , $author );
    }
}

##  split title search string at space and push if four or more characters
my @titulu_array = split( ' ', $titulu_str );
foreach my $word (@titulu_array) {
    if ( length($word) >= 4 ) {
	push( @titulu_sch , $word );
    }
}


##  find word matches
my @palori;
foreach my $wdkey (sort keys %smword) {
    foreach my $palora (@palori_sch) {
	if ($palora eq $wdkey) {
	    push( @palori , @{ $smword{$wdkey} } );
	}
    }
}
@palori = uniq(@palori);

##  find author matches
my @autori;
foreach my $aukey (sort keys %smauth) {
    foreach my $author (@autori_sch) {
	if ($author eq $aukey) {
	    push( @autori , @{ $smauth{$aukey} } );
	}
    }
}
@autori = uniq(@autori);

##  find word matches
my @tituli;
foreach my $ttkey (sort keys %smtitle) {
    foreach my $word (@titulu_sch) {
	if ($word eq $ttkey) {
	    push( @tituli , @{ $smtitle{$ttkey} } );
	}
    }
}
@tituli = uniq(@tituli);


##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  identify the matches
my @matches ;

if ( $#autori_sch < 0 && $#palori_sch < 0 && $#titulu_sch < 0 ) {
    ##  no author search, no word search, no title search
    @matches = ();

} elsif ( $#palori_sch < 0  &&  $autori_str =~ /nicotra/ ) {
    ##  no word search, but author search on "nicotra"
    ##  return no matches
    @matches = ();

} elsif ( $#autori_sch < 0 && $#titulu_sch < 0 ) {
    ##  no author search, no title search, but word search
    @matches = @palori;

} elsif ( $#autori_sch < 0 && $#palori_sch < 0 ) {
    ##  no author search, no word search, but title search
    @matches = @tituli;

} elsif ( $#palori_sch < 0 && $#titulu_sch < 0 ) {
    ##  no word search, no title search, but author search
    @matches = @autori;    

} elsif ( $#palori_sch < 0 ) {
    ##  no word search, but title and author search
    my %union ;
    my %isect;
    foreach my $key (@tituli, @autori) {
	$union{$key}++ && $isect{$key}++
    }
    #my @union_keys = keys %union;
    #my @isect_keys = keys %isect;

    @matches = keys %isect;    

} elsif ( $#autori_sch < 0 ) {
    ##  no author search, but title and word search
    my %union ;
    my %isect;
    foreach my $key (@palori, @tituli) {
	$union{$key}++ && $isect{$key}++
    }
    #my @union_keys = keys %union;
    #my @isect_keys = keys %isect;

    @matches = keys %isect;    
    
} elsif ( $#titulu_sch < 0 ) {
    ##  no title search, but word and author search
    my %union ;
    my %isect;
    foreach my $key (@palori, @autori) {
	$union{$key}++ && $isect{$key}++
    }
    #my @union_keys = keys %union;
    #my @isect_keys = keys %isect;

    @matches = keys %isect;    
    
} else {
    ##  title, word and author search

    my %unionA ;
    my %isectA ;
    foreach my $key (@palori, @autori) {
	$unionA{$key}++ && $isectA{$key}++
    }
    #my @unionA_keys = keys %unionA;
    my @isectA_keys = keys %isectA;

    my %unionB ;
    my %isectB ;
    foreach my $key (@isectA_keys, @tituli) {
	$unionB{$key}++ && $isectB{$key}++
    }
    #my @unionB_keys = keys %unionB;
    #my @isectB_keys = keys %isectB;
    
    @matches = keys %isectB;
}

##  make list unique (should already be unique)
@matches = uniq(@matches);


##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  PREPARE HTML
##  ======= ====

##  prepare HTML output
my $otlines ;

##  sorry if not found, otherwise return the cosine-similarity
if ( $#matches < 0 ) {

    ##  if search came up empty
    
    ##  open outer DIV to limit width
    $otlines .= '<div class="transconj">' ."\n";
    ##  open row
    $otlines .= '<div class="row">' ."\n";
    
    if ( $autori_str eq "" && $palori_str eq "" && $titulu_str eq "" ) {
	##  no author search, no word search
	$otlines .= '<p>Attrova na palora o na frasi ntra li pruverbi e versi di puisia!</p>' ."\n";
	$otlines .= '<p>Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;

    } elsif ( $palori_str eq "" && $autori_str =~ /nicotra/ ) {
	##  no four-character word search and author search on "nicotra"
	##  return no matches
	$otlines .= '<p>Ci sunnu tanti pruverbi di Nicotra!</p>' ."\n";
	$otlines .= '<p>Abbisogna junciri na palora o frasi a la ricerca.</p>' ."\n";
	
    } elsif ( $autori_str eq "" && $titulu_str eq "" ) {
	##  no author or title search, but word search
	$otlines .= '<p>' . "Nun c'è un esempiu " ;
	if ( $palori_str =~ / / ) {
	    $otlines .= ' dâ frasi: &nbsp; ' ;
	} else {
	    $otlines .= ' dâ palora: &nbsp; ' ;
	}
	$otlines .= '<b>' . $palori_str .'</b></p>' ."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;

    } elsif ( $autori_str eq "" && $palori_str eq "" ) {
	##  no author or word search, but title search
	$otlines .= '<p>' . "Nun c'è un tìtulu " ;
	if ( $titulu_str =~ / / ) {
	    $otlines .= ' câ frasi: &nbsp; ' ;
	} else {
	    $otlines .= ' câ palora: &nbsp; ' ;
	}
	$otlines .= '<b>' . $titulu_str .'</b></p>' ."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;


    } elsif ( $palori_str eq "" && $titulu_str eq "" ) {
	##  no word or title search, but author search
	$otlines .= '<p>' . "Nun c'è un esempiu di l'autori: " ;
	$otlines .= '<b>' . $autori_str .'</b></p>' ."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;
	
    } elsif ( $titulu_str eq "" ) {
	##  no title search, but word search and author search
	$otlines .= '<p>' . "Nun c'è un esempiu " ;
	if ( $palori_str =~ / / ) {
	    $otlines .= ' dâ frasi: &nbsp; ' ;
	} else {
	    $otlines .= ' dâ palora: &nbsp; ' ;
	}
	$otlines .= '<b>' . $palori_str .'</b>' ."\n";
	$otlines .= " &nbsp; di l'autori: " .' &nbsp; <b>'.  $autori_str .'</b></p>'."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;

    } elsif ( $autori_str eq "" ) {
	##  no author search, but word search and title search
	$otlines .= '<p>' . "Nun c'è un esempiu " ;
	if ( $palori_str =~ / / ) {
	    $otlines .= ' dâ frasi: &nbsp; ' ;
	} else {
	    $otlines .= ' dâ palora: &nbsp; ' ;
	}
	$otlines .= '<b>' . $palori_str .'</b>' ."\n";
	$otlines .= " &nbsp; e dû tìtulu " .' &nbsp; <b>'.  $titulu_str .'</b></p>'."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;
	
    } elsif ( $palori_str eq "" ) {
	##  no word search, but author and title search
	$otlines .= '<p>' . "Nun c'è un esempiu di l'autori: " .' &nbsp; ';
	$otlines .= '<b>' . $autori_str .'</b>' ."\n";
	$otlines .= " &nbsp; e dû tìtulu " .' &nbsp; <b>'.  $titulu_str .'</b></p>'."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;
	
    } else {
	##  word, title and author search
	$otlines .= '<p>' . "Nun c'è un esempiu " ;
	if ( $palori_str =~ / / ) {
	    $otlines .= ' dâ frasi: &nbsp; ' ;
	} else {
	    $otlines .= ' dâ palora: &nbsp; ' ;
	}
	$otlines .= '<b>' . $palori_str .'</b>' ."\n";
	$otlines .= " &nbsp; di l'autori: " .' &nbsp; <b>'.  $autori_str .'</b> '."\n";
	$otlines .= " &nbsp; e dû tìtulu " .' &nbsp; <b>'.  $titulu_str .'</b></p>'."\n";
	$otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	$otlines .= $example;

    }
    
    ##  close row
    $otlines .= '</div>' ."\n"; 
    ##  close outer DIV to limit width
    $otlines .= '</div>' ."\n";
    
    ##  close empty search
        
} else {

    ##  found matches
    ##  store matching text in holder
    my %othash;

        ##  retrieve vocab notes
    my $vnhash = retrieve( $vocab_notes );
    my %vnotes = %{ $vnhash } ;

    
    ##  retrieve vocabulary subroutines
    my $vthash  = retrieve( $verb_tools );
    my $vbconj  =   $vthash->{vbconj} ;
    my %vbsubs  = %{$vthash->{vbsubs}};
    
    ##  loop through the matches to find matching text
    foreach my $palora (@matches) {

	if ( ! defined $vnotes{$palora} ) {
	    my $blah = "ERROR -- no hash key for:  " . $palora . "\n";
	    ## print $blah;
	} else {

	    ##  get word header HTML
	    my $header = mk_wdheader( $palora , \%vnotes , $vbconj , \%vbsubs ) ;

	    ##  find matching poetry and make HTML
	    my @poem_matches = find_poem_matches( $palora , $autori_str , $palori_str , $titulu_str , "poetry" , \%vnotes ); 
	    my $poem_html = mk_notex_list( 'puisìa:' , \@poem_matches ) ;

	    ##  find matching prose and make HTML
	    my @prose_matches = find_poem_matches( $palora , $autori_str , $palori_str , $titulu_str , "prose" , \%vnotes ); 
	    my $prose_html = mk_notex_list( 'prosa:' , \@prose_matches ) ;

	    ##  find matching proverbs and make HTML
	    my @proverb_matches = find_poem_matches( $palora , $autori_str , $palori_str , $titulu_str , "proverb" , \%vnotes ); 
	    my $proverbs_num = ($#proverb_matches > 0) ? 'pruverbi:' : 'pruverbiu:' ;
	    my $proverb_html = mk_notex_list( $proverbs_num , \@proverb_matches ) ; 

	    ##  store poems and proverbs on the output hash
	    if ( $#poem_matches > -1 ) {
		$othash{$palora}{header} = $header;
		$othash{$palora}{poetry} = $poem_html;
	    }

	    if ( $#prose_matches > -1 ) {
		$othash{$palora}{header} = $header;
		$othash{$palora}{prose} = $prose_html;
	    }

	    if ( $#proverb_matches > -1 ) {
		$othash{$palora}{header} = $header;
		$othash{$palora}{proverb} = $proverb_html;
	    }
	}
    }
    ##  end loop through the matches

    
    ##  now prepare their HTML output
    ##  making sure that at least one match
    my @othash_keys = sort {lc($smsubs{rid_accents}($a)) cmp lc($smsubs{rid_accents}($b))} keys %othash ;
    
    if ( $#othash_keys < 0 ) {
	
	##  open div for no matches
	$otlines .= '<div class="transconj">' ."\n";

	if ( $autori_str eq "" ) {
	    ##  no author search, but word search
	    $otlines .= '<p>' . "Nun c'è un esempiu " ;
	    if ( $palori_str =~ / / ) {
		$otlines .= ' dâ frasi: &nbsp; ' ;
	    } else {
		$otlines .= ' dâ palora: &nbsp; ' ;
	    }
	    $otlines .= '<b>' . $palori_str .'</b></p>' ."\n";
	    $otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	    $otlines .= $example;
	
	} elsif ( $palori_str eq "" ) {
	    ##  no word search, but author search
	    $otlines .= '<p>' . "Nun c'è un esempiu di l'autori: " ;
	    $otlines .= '<b>' . $autori_str .'</b></p>' ."\n";
	    $otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	    $otlines .= $example;
	    
	} else {
	    ##  word search and author search
	    $otlines .= '<p>' . "Nun c'è un esempiu " ;
	    if ( $palori_str =~ / / ) {
		$otlines .= ' dâ frasi: &nbsp; ' ;
	    } else {
		$otlines .= ' dâ palora: &nbsp; ' ;
	    }
	    $otlines .= '<b>' . $palori_str .'</b>' ."\n";
	    $otlines .= "  &nbsp; di l'autori: " .' &nbsp; <b>'.  $autori_str .'</b></p>'."\n";
	    $otlines .= '<p>Prova di novu! Almenu una palora havi a aviri 4&nbsp;o chiù littri.</p>'."\n";
	    $otlines .= $example;
	}
	
	##  close div for no matches
	$otlines .= '</div>' ."\n";
	
	
    } else {
    
	##  for each match, open the file
	foreach my $palora (@othash_keys) {

	    ##  open div for the matche
	    $otlines .= '<div class="transconj">' ."\n";

	    ##  poetry and proverbs to add
	    my $add_poem    = ( ! defined $othash{$palora}{poetry}  ) ? "" : $othash{$palora}{poetry} ;
	    my $add_prose   = ( ! defined $othash{$palora}{prose}   ) ? "" : $othash{$palora}{prose} ;
	    my $add_proverb = ( ! defined $othash{$palora}{proverb} ) ? "" : $othash{$palora}{proverb}; 
	    
	    ##  add the header, poetry and proverbs
	    $otlines .= $othash{$palora}{header} ;
	    $otlines .= $add_poem ;
	    $otlines .= $add_prose ;
	    $otlines .= $add_proverb ;

	    ##  add horizontal line
	    $otlines .= '<hr>' ."\n";
	    
	    ##  close div for the match
	    $otlines .= '</div>' ."\n";

	}
    }
}

##  remove last horizontal line
$otlines =~ s/<hr>\n<\/div>\n$/<\/div>\n/;

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  OUTPUT the HTML
##  ====== === ====

print $html_head;
print $html_form;
print $otlines;
print $html_foot;


##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  SUBROUTINES
##  ===========

##  get the indices of the sorted values
sub idxsort {
    my @vals = @_ ;
    my @idx = 0..$#vals;
    my @idxsorted = sort {$vals[$b] <=> $vals[$a]} @idx ;
    return @idxsorted;
}

## tip of the hat to List::MoreUtils for this sub
sub uniq { 
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}


##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  HTML items
##  ==== =====

##  make HTML header
sub mk_header {

    ##  top navigation panel
    my $topnav = $_[0] ;

    ##  the words, title and author searched for
    my $palori_str = ( ! defined $_[1] ) ? "" : $_[1] ;
    my $autori_str = ( ! defined $_[2] ) ? "" : $_[2] ;
    my $titulu_str = ( ! defined $_[3] ) ? "" : $_[3] ;

    $palori_str = ( $palori_str !~ /[a-z]/ ) ? "" : "pa: " . $palori_str . ", ";
    $autori_str = ( $autori_str !~ /[a-z]/ ) ? "" : "au: " . $autori_str . ", ";
    $titulu_str = ( $titulu_str !~ /[a-z]/ ) ? "" : "ti: " . $titulu_str . ", ";

    ##  create search string
    my $search = $palori_str . $titulu_str . $autori_str ;
    $search =~ s/, $//;
    $search =~ s/^ //;
    $search =~ s/ $//;
    
    ##  text to insert into the title
    my $title_insert = ( $search eq "" ) ? "" : $search .' :: ';
  
    ##  prepare output HTML
    my $ottxt ;
    $ottxt .= "Content-type: text/html\n\n";
    $ottxt .= '<!DOCTYPE html>' . "\n" ;
    $ottxt .= '<html>' . "\n" ;
    $ottxt .= '  <head>' . "\n" ;
    $ottxt .= '    <title>' . $title_insert  . 'Trova na Palora :: Napizia</title>' ."\n";

    ##  select description
    if ( $title_insert ne "") {
	$ottxt .= '    <meta name="DESCRIPTION" content="puisia e pruverbi pi: '. $search . ', '."\n";
	$ottxt .= '          poetry and proverbs for: ' . $search . '">' ."\n";
    } else { 
	$ottxt .= '    <meta name="DESCRIPTION" content="Attrova na palora o na frasi ntra li pruverbi e versi di puisia. '."\n";
	$ottxt .= '          Find a word or phrase within the proverbs and verses of poetry.">' ."\n";
    }    

    ##  continue header
    $ottxt .= '    <meta name="KEYWORDS" content="poetry, proverbs, Sicilian, Sicilian language">' ."\n";
    $ottxt .= '    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">' . "\n" ;
    $ottxt .= '    <meta name="Author" content="Eryk Wdowiak">' . "\n" ;
    $ottxt .= '    <link rel="stylesheet" type="text/css" href="/css/eryk.css">' . "\n" ;
    $ottxt .= '    <link rel="stylesheet" type="text/css" href="/css/eryk_theme-blue.css">' . "\n" ;
    $ottxt .= '    <link rel="stylesheet" type="text/css" href="/css/eryk_widenme.css">' . "\n" ;
    $ottxt .= '    <link rel="stylesheet" type="text/css" href="/css/dieli_forms.css">' . "\n" ;
    $ottxt .= '    <link rel="icon" type="image/png" href="/config/napizia-icon.png">' . "\n" ;
    $ottxt .= "\n";
    $ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    $ottxt .= '          title="SC-EN Dieli Dict"'."\n";
    $ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/dieli_sc-en.xml">'."\n";
    $ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    $ottxt .= '          title="SC-IT Dieli Dict"'."\n";
    $ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/dieli_sc-it.xml">'."\n";
    $ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    $ottxt .= '          title="EN-SC Dieli Dict"'."\n";
    $ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/dieli_en-sc.xml">'."\n";
    $ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    $ottxt .= '          title="IT-SC Dieli Dict"'."\n";
    $ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/dieli_it-sc.xml">'."\n";
    $ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    $ottxt .= '          title="Trova na Palora"'."\n";
    $ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/trova-palora.xml">'."\n";
    #$ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    #$ottxt .= '          title="Cosine Sim Skipgram"'."\n";
    #$ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/cosine-sim_skip.xml">'."\n";
    #$ottxt .= '    <link rel="search" type="application/opensearchdescription+xml"'."\n";
    #$ottxt .= '          title="Cosine Sim CBOW"'."\n";
    #$ottxt .= '          href="https://www.napizia.com/pages/sicilian/search/cosine-sim_cbow.xml">'."\n";
    $ottxt .= "\n";
    $ottxt .= '    <meta name="viewport" content="width=device-width, initial-scale=1">' . "\n" ;
    $ottxt .= '    <style>' . "\n" ;
    $ottxt .= '    p.zero { margin-top: 0em; margin-bottom: 0em; }' . "\n" ;
    $ottxt .= '    div.transconj { position: relative; margin: auto; width: 50%;}' . "\n" ;
    $ottxt .= '    @media only screen and (max-width: 835px) { ' . "\n" ;
    $ottxt .= '        div.transconj { position: relative; margin: auto; width: 90%;}' . "\n" ;
    $ottxt .= '    }' . "\n" ;

    ## ##  spacing for second column of Dieli collections
    ## ##  now handled by "eryk_widenme.css"
    ## $ottxt .= '    ul.ddcoltwo { margin-top: 0em; }' . "\n" ;
    ## $ottxt .= '    @media only screen and (min-width: 600px) { ' . "\n" ;
    ## $ottxt .= '        ul.ddcoltwo { margin-top: 2.25em; }' . "\n" ;
    ## $ottxt .= '    }' . "\n" ;
    
    $ottxt .= '    </style>' . "\n" ;
    $ottxt .= '  </head>' . "\n" ;

    open( TOPNAV , $topnav ) || die "could not read:  $topnav";
    while(<TOPNAV>){ chomp;  $ottxt .= $_ . "\n" ; };
    close TOPNAV ;

    $ottxt .= '  <!-- begin row div -->' . "\n" ;
    $ottxt .= '  <div class="row">' . "\n" ;
    $ottxt .= '    <div class="col-m-12 col-12">' . "\n" ;
    $ottxt .= '      <h1>Trova na Palora</h1>'."\n";
    $ottxt .= '    </div>' . "\n" ;
    $ottxt .= '  </div>' . "\n" ;
    $ottxt .= '  <!-- end row div -->' . "\n" ;
    $ottxt .= '  ' . "\n" ;
    $ottxt .= '  <!-- begin row div -->' . "\n" ;
    $ottxt .= '  <div class="row">' . "\n" ;
    
    return $ottxt ;
}

##  make footer
sub mk_footer {

    ##  footer navigation
    my $footnv = $_[0] ; 

    ##  prepare output
    my $othtml ;
    
    $othtml .= '  </div>' . "\n" ;
    $othtml .= '  <!-- end row div -->' . "\n" ;

    $othtml .= '<div class="row" style="margin: 5px 0px; border: 1px solid black; background-color: rgb(255,255,204);">'."\n";
    $othtml .= '  <div class="minicol"></div>'."\n";
    $othtml .= '  <div class="col-t-2"></div>'."\n";
    $othtml .= '  <div class="col-m-10 col-3">'."\n";
    $othtml .= '    <p style="margin-top: 0.25em; margin-bottom: 0.25em; padding-left: 0px;"><b><i>ricota di palori:</i></b></p>'."\n";
    $othtml .= '    <ul class="ricota-margin">'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_aviri">aviri</a> &amp; '."\n";
    $othtml .= '	<a href="/cgi-bin/sicilian.pl?search=COLL_have">to have</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_essiri">essiri</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_fari">fari</a></li>'."\n";
    $othtml .= '    </ul>'."\n";
    $othtml .= '  </div>'."\n";
    $othtml .= '  <div class="col-t-2"></div>'."\n";
    $othtml .= '  <div class="col-m-10 col-2">'."\n";
    $othtml .= '    <ul class="ricota-margin-plus">'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_places">lu munnu</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_timerel">lu tempu</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_daysweek">li jorna</a></li>'."\n";
    $othtml .= '    </ul>'."\n";
    $othtml .= '  </div>'."\n";
    $othtml .= '  <div class="minicol"></div>'."\n";
    $othtml .= '  <div class="col-t-2"></div>'."\n";
    $othtml .= '  <div class="col-m-10 col-3">'."\n";
    $othtml .= '    <ul class="ricota-margin-plus">'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_months">li misi</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_holidays">li festi</a></li>'."\n";
    $othtml .= '      <li><a href="/cgi-bin/sicilian.pl?search=COLL_seasons">li staggiuni</a></li>'."\n";
    $othtml .= '    </ul>'."\n";
    $othtml .= '  </div>'."\n";
    $othtml .= '  <div class="col-t-2"></div>'."\n";
    $othtml .= '  <div class="col-m-10 col-3">'."\n";
    $othtml .= '    <p style="margin-top: 0.25em; margin-bottom: 0.25em;"><b><i>lingua siciliana:</i></b></p>'."\n";
    $othtml .= '    <ul class="ricota-margin">'."\n";
    $othtml .= '      <li style="margin-bottom: 0.125em;"><a href="http://www.arbasicula.org/" '."\n";
    $othtml .= '          target="_blank">Arba Sicula</a></li>'."\n";
    $othtml .= '      <li style="margin-bottom: 0.125em;"><a href="http://www.dieli.net/" '."\n";
    $othtml .= '      	  target="_blank">Arthur Dieli</a></li>'."\n";
    $othtml .= '    </ul>'."\n";
    $othtml .= '  </div>'."\n";
    $othtml .= '</div>'."\n";
    $othtml .= '<div class="widenme"></div>'."\n";
    

    open( FOOTNAV , $footnv ) || die "could not read:  $footnv";
    while(<FOOTNAV>){ chomp;  $othtml .= $_ ."\n"; };
    close FOOTNAV ;
    
    return $othtml ;
}

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  make form
sub mk_form {

    ##  embedding and search
    my $in_palori = $_[0];
    my $in_autori = $_[1];
    my $in_titulu = $_[2]; 
    
    my $ottxt ;
    $ottxt .= '<form enctype="multipart/form-data" action="/cgi-bin/trova-palora.pl" method="post">' . "\n" ;
    $ottxt .= '<table style="max-width:500px;"><tbody>' ."\n";
    $ottxt .= '<tr><td><small>palora</small></td>' ."\n";
    $ottxt .= '<td colspan="2">' ."\n";
    $ottxt .= '<input type=text name="palori" value="'. $in_palori .'" size=27 maxlength=48>' ; 
    $ottxt .= '</td></tr>' . "\n" ;
    $ottxt .= '<tr><td><small>tìtulu</small></td>' ."\n";
    $ottxt .= '<td colspan="2">' ."\n";
    $ottxt .= '<input type=text name="titulu" value="'. $in_titulu .'" size=27 maxlength=48>' ; 
    $ottxt .= '</td></tr>' . "\n" ;
    $ottxt .= '<tr><td><small>autori</small></td>' ."\n";
    $ottxt .= '<td>' ."\n";
    $ottxt .= '<input type=text name="autori" value="'. $in_autori .'" size=15 maxlength=24>' ; 
    $ottxt .= '</td>' . "\n" ;
    $ottxt .= '<td align="right">' . '<input type="submit" value="Attrova">' . "\n" ;
    ## $ottxt .= '<input type=reset value="Clear Form">' . "\n" ; 
    $ottxt .= '</td></tr>' . "\n" ;
    $ottxt .= '</tbody></table>' . "\n" ;
    $ottxt .= '</form>' . "\n" ;
        
    return $ottxt ;
}

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##

##  make word header
sub mk_wdheader {

    ##  inputs for word header
    my $palora =   $_[0];
    my %vnotes = %{$_[1]};
    my $vbconj =   $_[2];
    my %vbsubs = %{$_[3]};
    
    ##  are we working with a verb?
    my %wdhash ;
    my $isverb = ( ! defined $vnotes{ $palora }{verb}     && 
		   ! defined $vnotes{ $palora }{reflex}   && 
		   ! defined $vnotes{ $palora }{prepend}  ) ? "false" : "true" ;
    if ( $isverb eq "true" ) {
	%wdhash = $vbsubs{conjugate}( $palora , \%vnotes , $vbconj , \%vbsubs ) ; 
    }
    
    ##  which word do we display?
    ( my $display = $palora ) =~ s/_([a-z])+$//;
    $display = ( ! defined $wdhash{inf} ) ? $display : $wdhash{inf} ;
    $display = ( ! defined $vnotes{$palora}{display_as} ) ? $display : $vnotes{$palora}{display_as} ;
    
    ##  parti di discursu 
    my $part_speech = $vnotes{ $palora }{part_speech} ;
    
    ##  translate to Sicilian
    $part_speech =~ s/^verb$/verbu/ ;
    $part_speech =~ s/^noun$/sust./ ;
    $part_speech =~ s/^adj$/agg./   ;
    $part_speech =~ s/^adv$/avv./   ;
    $part_speech =~ s/^prep$/prip./ ;
    $part_speech =~ s/^pron$/prun./ ;
    $part_speech =~ s/^conj$/cunj./ ;
	    
    ##  HEADER
    my $header;
    $header .= '<p><b><a href="/cgi-bin/cchiu-da-palora.pl?' . 'palora=' . $palora . '">' ; 
    $header .= $display . '</a></b>&nbsp;&nbsp;{'. $part_speech .'}</p>'."\n";

    return $header;
}

##  get stripped sample and author
sub get_sample_author {

    my $line = $_[0];
    $line = $smsubs{strip_line}($line , \%smsubs );
    
    ##  identify citation
    my $citation = $line ;
    $citation =~ s/^.*\(//;

    ##  make matching parenthesis
    my $cite_paren = $citation ;
    if ( $cite_paren =~ /\)/ && $cite_paren !~ /\(/ ) {
	$cite_paren =~ s/^/\(/
    }

    ##  identify sample
    my $sample   = $line ;
    $sample =~ s/$cite_paren//;
        
    ##  remove matching parenthesis
    $citation =~ s/[\(\)]//g;
    $sample   =~ s/[\(\)]//g;
    
    ##  identify title and author
    my $author = $citation ;
    my $title  = $citation ;
    $author =~ s/^.*",//;
    $title =~ s/$author//;

    ##  clean them up
    $sample =~ s/\s+/ /g; $author =~ s/\s+/ /g; $title =~ s/\s+/ /g; 
    $sample =~ s/\"//g;   $author =~ s/\"//g;   $title =~ s/\"//g;
    $sample =~ s/\,//g;   $author =~ s/\,//g;   $title =~ s/\,//g;
    $sample =~ s/^ //;    $author =~ s/^ //;    $title =~ s/^ //; 
    $sample =~ s/ $//;    $author =~ s/ $//;    $title =~ s/ $//; 

    ##  citations of Pitre's "Canti" and "Fiabe" have numbers
    $author = ( $title eq "canti" && $author =~ /pitre/ ) ? "pitre" : $author ;
    $author = ( $title eq "fiabe" && $author =~ /pitre/ ) ? "pitre" : $author ;
    
    ##  return stripped sample, author and title
    return( $sample , $author , $title );
}

##  find poem/proverb matches
sub find_poem_matches {

    my $palora     =   $_[0];
    my $autori_str =   $_[1];
    my $palori_str =   $_[2];
    my $titulu_str =   $_[3];
    my $typeof     =   $_[4];  ## "poetry", "prose", or "proverb"
    my %vnotes     = %{$_[5]};
    
    my @poem_matches;
        
    if ( ! defined $vnotes{$palora}{$typeof} ) {
	my $blah = "do nothing" ;
    } else {
	
	my @poetry  = @{ $vnotes{$palora}{$typeof} };
	foreach my $poem (@poetry) {
	    ##  get stripped sample and author
	    my ( $sample , $author , $title ) = get_sample_author( $poem );
	    
	    ##  fix "la mattina", "di marco" and "de vita"
	    $author =~ s/la mattina/la~mattina/g;
	    $author =~ s/di marco/di~marco/g;
	    $author =~ s/de vita/de~vita/g;

	    ##  add spacing
	    my @au_sch = split(' ',$author);
	    $author = ' ' . join( ' | ' , @au_sch ) . ' ';
	    $sample = ' ' . $sample . ' ';
	    $title  = ' ' . $title  . ' ';
	    
	    ##  create author search string
	    my $autori_new = $autori_str;
	    $autori_new =~ s/la mattina/la~mattina/g;
	    $autori_new =~ s/di marco/di~marco/g;
	    $autori_new =~ s/de vita/de~vita/g;
	    my @autori_list = split(' ',$autori_new );
	    
	    ##  create word search string
	    my $palori_new = ' ' . $palori_str . ' ';

	    ##  create title search string
	    my $titulu_new = ' ' . $titulu_str . ' ';
		    
	    ##  search sample and author
	    if ( $autori_str ne "" && $palori_str ne "" && $titulu_str ne "" ) {
		foreach my $author_new (@autori_list) {
		    my $author_sch = ' ' . $author_new . ' ';
		    if ( $author_sch =~ /$author/ && $sample =~ /$palori_new/ && $title =~ /$titulu_new/ ) {
			push( @poem_matches , $poem );
		    }
		}

	    } elsif ( $autori_str ne "" && $titulu_str ne "" ) {
		foreach my $author_new (@autori_list) {
		    my $author_sch = ' ' . $author_new . ' ';
		    if ( $author_sch =~ /$author/ && $title =~ /$titulu_new/ ) {
			push( @poem_matches , $poem );
		    }
		}

	    } elsif ( $autori_str ne "" && $palori_str ne "" ) {
		foreach my $author_new (@autori_list) {
		    my $author_sch = ' ' . $author_new . ' ';
		    if ( $author_sch =~ /$author/ && $sample =~ /$palori_new/ ) {
			push( @poem_matches , $poem );
		    }
		}

	    } elsif ( $palori_str ne "" && $titulu_str ne "" ) {
		if ( $sample =~ /$palori_new/ && $title =~ /$titulu_new/ ) {
		    push( @poem_matches , $poem );
		}

	    } elsif ( $titulu_str ne "" ) {
		if ( $title =~ /$titulu_new/ ) {
		    push( @poem_matches , $poem );
		}
		
	    } elsif ( $palori_str ne "" ) {
		if ( $sample =~ /$palori_new/ ) {
		    push( @poem_matches , $poem );
		}		       			
	    } elsif ( $autori_str ne "" ) {
		foreach my $author_new (@autori_list) {	
		    my $author_sch = ' ' . $author_new . ' ';
		    if ( $author_sch =~ /$author/ ) {
			push( @poem_matches , $poem );
		    }
		}
	    }
	    
	}
    }

    ##  return matching poems/proverbs
    return @poem_matches ;
}

##  make list of examples
sub mk_notex_list {

    my $typeof =     $_[0] ;
    my @inarray = @{ $_[1] } ;

    my $othtml ;

    ## $othtml .= '<div class="transconj">' ."\n"; 
    $othtml .= '<p style="margin-bottom: 0.25em;"><i>' . $typeof . '</i></p>' ."\n";
    $othtml .= '<ul style="margin-top: 0.25em;">' ."\n";
    foreach my $line (@inarray) {

	##  clean up dashes
	$line =~ s/\-\-/\&ndash;/g;
	    
	##  append the line
	$othtml .= "<li>" . $line . "</li>" ."\n";
    }
    $othtml .= "</ul>" ."\n";
    ## $othtml .= "</div>" ."\n";
    
    return $othtml ;
}

##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##  ##
