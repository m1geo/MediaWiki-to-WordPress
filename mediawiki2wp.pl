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
my $post_type = 'wiki';
my $ping_status = 'open';
my $parent = 0;
my $comment_status = 'open';
my $url = 'http://example.com/';


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

	foreach my $page_i (@pages) {
		$rss->add_item(
			title		=> $page_i->{title},
			link		=> $url.$post_type.'/'.&pageSlug($page_i->{title}),
			description	=> '',
			dc		=>
			{
				creator		=> $page_i->{revision}{contributor}{username}
			},
			content		=>
			{
				
				encoded	=> $page_i->{revision}{text}{CONTENT}
			},
			wp		=>
			{
				post_date	=> &ctime($page_i->{revision}{timestamp}),
				post_name	=> &pageSlug($page_i->{title}),
				status		=> 'publish',
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
