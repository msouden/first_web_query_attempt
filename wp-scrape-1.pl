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
my $dir = dir("/"); # URL list resides in same dir
my $url-list = $dir->file("url-list.txt"); #this exists at start
my $not-found-plugins = $dir->file("not-found-plugins.log"); #this gets created on running
my $plugins-flagged-old = $dir->file("plugins-flagged-old"); #this gets created on running


# openr() returns an IO::File object to read from --- Making handles here cause I think I'm supposed to?
my $url-list_handle = $url-list->openr();
my $not-found-plugins_handle = $not-found-plugins->openr();
my $plugins-flagged-old_handle = $plugins-flagged-old->openr();

# Read in one URL at a time from url-list.txt
while( my $pluginURL = $url-list_handlel->getline() ) {

	wq($pluginURL)		# running Web::Query on the URL

		#___ IF _____ this needs to be an if statement here - looking to see if it's a 404 first

			->find('p.no-plugin-results')  	# if this <p> element is found, the plugin page didn't resolve.
											
			print $pluginURL" was not found.\n";   #then print such and 
					return;

		    # pipe this URL to the not found log - and doing it here because nothing more to do.
	    	$not-found-plugins_handle->print($pluginURL"\n");
										

		#___ THEN ____ then we can jettison this one and go on to the next - 

	#Now we can start plucking items in order of how they appear on page:	

	# Is it flagged as an old plugin? ------------------
		->find('div.plugin-notice-open-old')  
		->each( sub {
			my $old_flag = $_->find('span.plugin-notice-banner-msg')->text;
			print "$pluginURL was flagged as old.";  # lil feedback here
			# saving contents of the span in case age changes in these notices plugin-to-plugin - will know how old.


	#Getting the Title ------------------------
		->find('div#plugin-title')
		->each( sub {
			my $plugin_name = $_->find('h2')->text;
			print "Getting Metadata for: $plugin_name... ";


	#Tags ------------------------ 
		->find('div#plugin-tags')
		->each( sub {
			my $plugin_tags = $_->find('a')->text;					#TO DO - several tags -  should be an array:
																	# need to figure out how to 
																	#get tags until there are no more


	#Version Requirements (min/max) 
		->find('div.col-3')
		->each( sub {
			my $min_reqs = $_->find('p')
							 ->first->text;		#this might be dicy. muliple items in same container.

		->find('div.col-3')
		->each( sub {
			my $max_reqs = $_->find('p')
							 ->second->text;	#same container, separated by a break & <strong>text</strong>. Does "second" work?


	#Last Updated				dicyness here too- want to collect the attribute "content" on the meta tag with  
	#									an attribute of itemprop="dateModified"
		->find('div.col-3')
		->each( sub {
			my $last_update = $_->find('p > meta itemprop="dateModified"')
								->attr('content');


	#User Downloads					Similarly dicey SYNTAX HERE. Want the attribute "content" on the meta tag with  
	#									an attribute of itemprop="interactionCount" 
	#									Bonus for stripping off "Userdownloads:" that's prepended to the value 
		->find('div.col-3')
		->each( sub {
			my $downloads = $_->find('p > meta itemprop="interactionCount"')
								->attr('content');


	#Ratings Summary				
	#									

		->find('div.col-3')
		->each( sub {
			my $avg_rating = $_->find('div.left > meta itemprop="ratingValue"')
								->attr('content');

		->find('div.col-3')
		->each( sub {
			my $rating_count = $_->find('div.left > meta itemprop="ratingCount"')
								->attr('content');

	#Star Ratings				
	#																		
		->find('div.col-3')
		->each( sub {
			my $five-stars = $_->find('div.left > div:nth-child(6) > span')->text;
			my $four-stars = $_->find('div.left > div:nth-child(7) > span')->text;
			my $three-stars = $_->find('div.left > div:nth-child(8) > span')->text;
			my $two-stars = $_->find('div.left > div:nth-child(9) > span')->text;
			my $one-star = $_->find('div.left > div:nth-child(10) > span')->text;



	#Authors ------------------------
		->find('div.plugin-contributor-info')			#TO DO - up to 80+ authors on some plugins- need an array
		->each( sub {
			my $author = $_->find('div > a')->text;	
			my $author_url = $_->find('div > a')	
								->attr('href');				
		

	# NOW Outputing...

	# Logging older plugins seperately AND in main file
	$plugins-flagged-old_handle->print($plugin_name" , "$pluginURL" , "$old_flag);


	# Okay with tags and authors having variable length arrays I have graduated from being able to just dump to a CSV. 
	# So what's the proper vehicle to output to?




}
