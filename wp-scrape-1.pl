#!/usr/bin/perl
use strict;
use warnings;
use Web::Query;
use LWP::Simple;
use Path::Class;
use autodie; # die if problem reading or writing a file

	
# at some point will need a delay of 2000 ms. Nice and slow to not get banned.
# maybe right after loading the next URL?
# bring in first URL from url-list.txt making variable $pluginURL

# Is this right?
my $dir = dir("."); # URL list resides in same dir
my $url_list = $dir->file("url-list.txt"); #this exists at start
my $not_found_plugins = $dir->file("not_found_plugins.log"); #this gets created on running
my $plugins_flagged_old = $dir->file("plugins_flagged_old.log"); #this gets created on running


# openr() returns an IO::File object to read from --- Making handles here cause I think I'm supposed to?
my $url_list_handle = $url_list->openr();
my $not_found_plugins_handle = $not_found_plugins->openr();
my $plugins_flagged_old_handle = $plugins_flagged_old->openr();


	print "plugin_name , plugin_URL , downloads , avg_rating , rating_count  , five_stars , four_stars , three_stars , two_stars, one_star , last_update , max_reqs , min_reqs , tags , contributors ,  ";


# Read in one URL at a time from url-list.txt
while( my $plugin_URL = $url_list_handle->getline() ) {

	my($page) = wq($plugin_URL);
	$page		# running Web::Query now? This doesn't seem right.

		if($page){ #___  looking to see if the URL resolves to an actual plugin page, or that alt-404-ish search result page.

			$page->find('p.no-plugin-results')  	# if this <p> element is found, the plugin page didn't resolve.
													# don't need to capture the contents of p.no-plugin-results
													# just need like "if this is exists, record such and skip to the next one"
											
			print $pluginURL" resolved to that stupid NOT 404 page.\n";   #then print such and 

			# $not_found_plugins_handle->print($pluginURL"\n");   <- log entry if we don't get a plugin page (for later)


					return;

		#___So if the page loaded IS a plugin page - 
		#    then we can begin harvesting elements - so should everything below be part of the ELSE loop?

	#Harvesting:	

	# Is it flagged as an old plugin? ------------------
		$page->find('div.plugin-notice-open-old')  
		->each( sub {
			my $old_flag = $_->find('span.plugin-notice-banner-msg')->text;
			print "$pluginURL was flagged as old.";  # lil feedback here
			})# saving contents of the span in case age changes in these notices plugin-to-plugin - will know how old.


	#Getting the Title ------------------------
		$page->find('div#plugin-title')
		->each( sub {
			my $plugin_name = $_->find('h2')->text;
			#print "Getting Metadata for: $plugin_name... ";     #some feedback for later when outputing to file
			})


	#Tags ------------------------ 
		$page->find('div#plugin-tags')
		->each( sub {
			my $plugin_tags = $_->find('a')->text;					#TO DO - several tags -  should be an array:
		})															# need to figure out how to 
																	#get tags until there are no more


	#Version Requirements (min/max) 
		$page->find('div.col-3')
		->each( sub {
			my $min_reqs = $_->find('p')
							 ->first->text;		#this might be dicy. muliple items in same container.
		})		

		$page->find('div.col-3')
		->each( sub {
			my $max_reqs = $_->find('p')
							 ->second->text;	#same container, separated by a break & <strong>text</strong>. Does "second" work?
		})


	#Last Updated				dicyness here too- want to collect the attribute "content" on the meta tag with  
	#									an attribute of itemprop="dateModified"
		$page->find('div.col-3')
		->each( sub {
			my $last_update = $_->find('p > meta itemprop="dateModified"')
								->attr('content');
		})


	#User Downloads					Similarly dicey SYNTAX HERE. Want the attribute "content" on the meta tag with  
	#									an attribute of itemprop="interactionCount" 
	#									Bonus for stripping off "Userdownloads:" that's prepended to the value 
		$page->find('div.col-3')
		->each( sub {
			my $downloads = $_->find('p > meta itemprop="interactionCount"')
								->attr('content');
		})


	#Ratings Summary				
	#									

		$page->find('div.col-3')
		->each( sub {
			my $avg_rating = $_->find('div.left > meta itemprop="ratingValue"')
								->attr('content');
		})

		$page->find('div.col-3')
		->each( sub {
			my $rating_count = $_->find('div.left > meta itemprop="ratingCount"')
								->attr('content');
		})

	#Star Ratings				
	#																		
		$page->find('div.col-3')
		->each( sub {
			my $five_stars = $_->find('div.left > div:nth-child(6) > span')->text;
			my $four_stars = $_->find('div.left > div:nth-child(7) > span')->text;
			my $three_stars = $_->find('div.left > div:nth-child(8) > span')->text;
			my $two_stars = $_->find('div.left > div:nth-child(9) > span')->text;
			my $one_star = $_->find('div.left > div:nth-child(10) > span')->text;
		})


	#Authors ------------------------
		$page->find('div.plugin-contributor-info')			#TO DO - up to 80+ authors on some plugins- need an array
		->each( sub {
			my $author = $_->find('div > a')->text;	
			my $author_url = $_->find('div > a')	
								->attr('href');				
		})		

	# NOW Outputing...

	print "$plugin_name , $plugin_URL , $downloads , $avg_rating , $rating_count  , $five_stars , $four_stars , $three_stars , $two_stars, $one_star , $last_update , $max_reqs , $min_reqs , ";

	# Logging older plugins seperately AND in main file
	# Printing it to a file later:
	# $plugins_flagged_old_handle->print($plugin_name" , "$pluginURL" , "$old_flag);


}
