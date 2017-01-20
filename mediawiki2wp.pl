#!/usr/bin/perl

# Modified by George Smart, M1GEO
# Originally from: http://www.analogrithems.com/rant/portfolio/mediawiki2wordpress/
# Fri 20 Jan 2017

use strict;
use warnings;

use XML::Smart;
use XML::RSS;
use Date::Parse;
use POSIX qw/strftime/;

use vars qw/ %opt /;

my $version = "$0 v0.1";
my $post_type = 'page';
my $ping_status = 'closed';
my $parent = 0;
my $comment_status = 'closed';
my $page_status = 'draft'; # mark as draft and I publish when checked.
my $url = 'http://new.george-smart.co.uk/wordpress';
my $imgurl = $url . '/wp-content/uploads';


#
# Command line options processing
#
sub init(){
	use Getopt::Std;
	my $opt_string = 'hvVf:o:u:';
	getopts( "$opt_string", \%opt ) or usage();
	if($opt{V}){
		print $version."\n";
		exit;
	}
	if($opt{u}){
		$url = $opt{u};
	}
	usage() if $opt{h};
	usage() if !$opt{f};
	main();
}

sub usage(){
	print STDERR <<"EOF";
$0 -f <mediaWikiFile.xml> [-o <outputfile>] [-v] [-h] [-V]

-f 	The XML file that was exported from media wiki
-o	Output file to store the wordpress XML in.  If not defined, goes straight to STDOUT
-h 	This help message
-u	Base URL
-v	Verbose
-V	Version
EOF
exit;
}

sub pageSlug(){
	my $name = lc(shift());
	$name =~ s/[^\w]/_/g;
	$name =~ s/ /_/g;
	return $name;
}

sub ctime(){
	my $tm = str2time(shift());
	return strftime('%Y-%m-%d %T',localtime($tm));
}
sub main(){

	print $opt{f}."\n";
	my $XML = XML::Smart->new($opt{f},'XML::Smart::Parser');
	my $rss = XML::RSS->new(version=>'2.0');
	$rss->add_module(prefix=>'content', uri=>'http://purl.org/rss/1.0/modules/content/');
	$rss->add_module(prefix=>'wfw', uri=>'http://wellformedweb.org/CommentAPI/');
	$rss->add_module(prefix=>'dc', uri=>'http://purl.org/dc/elements/1.1/');
	$rss->add_module(prefix=>'wp', uri=>'http://wordpress.org/export/1.0/');
	

	$rss->channel(
		title		=> 'MediaWiki to Wordpres Migrator',
		link		=> 'http://analogrithems.com/rant/mediawiki2wordpress',
		language 	=> 'en',
		decription 	=> 'Migration Script to migrate mediawiki pages to wordpress pages',
		wp		=>
		{
			base_site_url 	=> $url,
			base_blog_url	=> $url,
			wxr_version	=> 1.1,
			author		=>
			{
				author_id	=> 2,
				author_login	=> 'admin',
				author_email	=> '',
				author_display_name => '',
				author_first_name   => '',
				author_last_name    => ''
			}
		}
	);

	my @pages = @{$XML->{mediawiki}{page}};
	my $content_temp = "";
	my $mw_link = "";
	my @img;
	foreach my $page_i (@pages) {
		$content_temp = $page_i->{revision}{text}{CONTENT};
		$mw_link = $page_i->{title};
		$mw_link =~ s/ /_/g;
		$mw_link =~ s/[^\w]/_/g;
		
		# Parse for [[Category - just flag it up
		$content_temp =~ s/\[{2}Category(.*?)\]{2}/<b>FIXME_Category$1 <\/b>/g;
		
		# Parse for [[User - just flag it up
		$content_temp =~ s/\[{2}User(.*?)\]{2}/<b>FIXME_User$1 <\/b>/g;
		
		# Parse for [[MediaWiki - just flag it up
		$content_temp =~ s/\[{2}MediaWiki(.*?)\]{2}/<b>FIXME_MediaWiki$1 <\/b>/g;
		
		# Parse for [[Media - make simple hyperlinks
		$content_temp =~ s/\[{2}Media:(.*?)\|(.*?)\]{2}/<a href=\"$1\">$2<\/a>/g;
		$content_temp =~ s/\[{2}Media:(.*?)\]{2}/<a href=\"$1\">$1<\/a>/g;
		
		# Parse for [[File - make simple hyperlinks
		$content_temp =~ s/\[{2}File:(.*?)\|(.*?)\]{2}/<a href=\"$1\">$2<\/a>/g;
		$content_temp =~ s/\[{2}File:(.*?)\]{2}/<a href=\"$1\">$1<\/a>/g;
		
		# Parse (or try to) the [[Image:.....]] tags.
		while($content_temp =~ /\[{2}Image:(.+?)\]{2}/g ) {
			@img = split('\|', $1); #pull in the match, and split on |
			my $fn = $img[0]; #filename always first
			my $wd = 0;
			my $at = "";
			my $imstr = "";
			my @dt = split('-', &ctime($page_i->{revision}{timestamp})); # date
			
			# loop through all vars looking for one with "px"
			for (my $i=1; $i<scalar(@img); $i++) {
				# pixel size of image
				if ($img[$i] =~ m/px$/) {
					$wd = 0 + $img[$i]; # this isn't the best way to do this, but meh!
				}
				# alt text of image
				if ( ($img[$i] !~ /px$/) && ($img[$i] !~ /^right$/i) && ($img[$i] !~ /^left$/i) && ($img[$i] !~ /^center$/i) && ($img[$i] !~ /^centre$/i) &&  ($img[$i] !~ /^thumb$/i) ) {
					$at = $img[$i];
					$at =~ s/\"//g;
				}
			}
			# form string with tags we have.
			$imstr = "<img src=\"" . $imgurl . "/" . $dt[0] . "/" . $dt[1] . "/". $fn . "\"";
			if ($wd > 0) {$imstr = $imstr . " width=\"" . $wd . "\"";}
			if ($at ne "") {$imstr = $imstr . " alt=\"" . $at . "\"";}
			$imstr = $imstr . ">";
			# replace matching filenames with first matching index.
			$content_temp =~ s/\[{2}Image:$fn.*\]{2}/$imstr/g;
		}

		# Parse (or try to) the [[image:.....]] tags.  --- LOWER CASE I on Image.
		while($content_temp =~ /\[{2}image:(.+?)\]{2}/g ) {
			@img = split('\|', $1); #pull in the match, and split on |
			my $fn = $img[0]; #filename always first
			my $wd = 0;
			my $at = "";
			my $imstr = "";
			my @dt = split('-', &ctime($page_i->{revision}{timestamp})); # date
			
			# loop through all vars looking for one with "px"
			for (my $i=1; $i<scalar(@img); $i++) {
				# pixel size of image
				if ($img[$i] =~ m/px$/) {
					$wd = 0 + $img[$i]; # this isn't the best way to do this, but meh!
				}
				# alt text of image
				if ( ($img[$i] !~ /px$/) && ($img[$i] !~ /^right$/i) && ($img[$i] !~ /^left$/i) && ($img[$i] !~ /^center$/i) && ($img[$i] !~ /^centre$/i) &&  ($img[$i] !~ /^thumb$/i) ) {
					$at = $img[$i];
					$at =~ s/\"//g;
				}
			}
			# form string with tags we have.
			$imstr = "<img src=\"" . $imgurl . "/" . $dt[0] . "/" . $dt[1] . "/". $fn . "\"";
			if ($wd > 0) {$imstr = $imstr . " width=\"" . $wd . "\"";}
			if ($at ne "") {$imstr = $imstr . " alt=\"" . $at . "\"";}
			$imstr = $imstr . ">";
			# replace matching filenames with first matching index.
			$content_temp =~ s/\[{2}image:$fn.*\]{2}/$imstr/g;
		}

		#$content_temp =~ s/\[{1}([\S&&[^\]]+?)\s(.*?)\]{1}/<a href=\"$1\">$2<\/a>/g;

		# Parse internal links (without description, using page title as description) -- not working?
		while($content_temp =~ /\[{2}(.*?)\]{2}/g ) {
			print STDERR "Found: " . $1 . "\n";
			@img = split('\|', $1); #pull in the match, and split on |
			my $u = &pageSlug($img[0]); #filename always first
			my $t = $img[0];
			if (scalar(@img) > 1) {
				$t = $img[1];
			}
			my $tstr = "<a href=\"" . $url. '/' . $u . "\">" . $t ."</a>" ;
			print STDERR $tstr . "\n";
			$content_temp =~ s/\[{2}$1\]{2}/$tstr/g;
		}

		$content_temp =~ s/\[{2}(.*?)\]{2}/<b>FIXME: $1 <\/b>/g;
		$content_temp =~ s/\[{1}([\S&&[^\]]+?)\s(.*?)\]{1}/<a href=\"$1\">$2<\/a>/g;
		
		#Uncomment to rewrite rule
		#print STDERR "\t RewriteRule ^/wiki/" . $mw_link ."\t/" . &pageSlug($page_i->{title}) . "\t[R=302]\n";
		$rss->add_item(
			title		=> $page_i->{title},
			#link		=> $url.$post_type.'/'.&pageSlug($page_i->{title}),
			link		=> $url.'/'.&pageSlug($page_i->{title}),
			description	=> '',
			dc		=>
			{
				creator		=> $page_i->{revision}{contributor}{username}
			},
			content		=>
			{
				encoded	=> $content_temp
			},
			wp		=>
			{
				post_date	=> &ctime($page_i->{revision}{timestamp}),
				post_name	=> &pageSlug($page_i->{title}),
				status		=> $page_status,
				post_type	=> $post_type,
				ping_status	=> $ping_status,
				comment_status 	=> $comment_status,
				menu_order	=> '',
				post_password	=> '',
				post_id		=> $page_i->{revision}{id},
				post_parent	=> $parent
				
			}
		);
	}
	if($opt{o}){
		$rss->save($opt{o});
	}else{
		print $rss->as_string."\n";
	}

}
init();
