#!/usr/bin/perl
use strict;
use warnings;
use Web::Query;
use LWP::Simple;
use Path::Class;
use autodie; # die if problem reading or writing a file


# Handles
open(my $url_list_handle, "<", "./url-list.txt");
open(my $not_found_plugins_handle, ">>", "./not_found_plugins.log" );
open(my $plugins_flagged_old_handle, ">>", "./plugins_flagged_old.log" );
open(my $results_handle, ">>", "./output.csv" );

# Columns
print "plugin_name , plugin_URL , downloads , avg_rating , rating_count  , five_stars , "
. "four_stars , three_stars , two_stars, one_star , last_update , max_reqs , min_reqs , "
. "tags , contributors ,  \n";

$results_handle->print ("Plugin Name,Plugin URL,Authors,Authors URL,Downloads,Average Rating,Rating Count,"
    . "5 Star Raings,4 Star Raings,3 Star Raings,2 Star Raings,1 Star Raings,"
    . "Last Update,Minimum WP Version Requirements,Tags\n");

# Read in one URL at a time from url-list.txt
while (my $plugin_URL = $url_list_handle->getline()) {
	chomp $plugin_URL;
	#print "fetching $plugin_URL\n";

	my($plugin_name, $downloads, $author, $author_URL, $avg_rating, $old_flag, $plugin_tags, $min_reqs,
	  $max_reqs, $last_update, $rating_count, $one_star,
	  $two_stars, $three_stars, $four_stars, $five_stars);

    my ($page) = wq($plugin_URL);

    if ($page) {                                                #___  Does the URL resolve to a plugin page 
		my $find_result = $page->find('p.no-plugin-results')->each(sub {
			print "$plugin_URL resolved to that stupid NOT 404 page.\n";
            $not_found_plugins_handle->print("$plugin_URL resolved to the fake NOT 404 page.\n");         #then print such
			last;
		});

        # $not_found_plugins_handle->print($plugin_URL"\n");            <- log entry if we don't get a plugin page (for later)

    }
    else {print "failed to fetch $plugin_URL\n";
            $not_found_plugins_handle->print("$plugin_URL not found.\n");
            next}

    #Harvesting:

    # Old Plugin Flag ------------------
    $page->find('div.plugin-notice-open-old span.plugin-notice-banner-msg')->each(
        sub {
            $old_flag = $_->text;
            print "$plugin_URL was flagged as old."; # lil feedback here
            $plugins_flagged_old_handle->print("$plugin_URL flagged as old.\n");
        }
    ); 


    # Getting the Title ------------------------
    $page->find('div#plugin-title h2')->each(
        sub {
            $plugin_name = $_->text;
        }
    );


    # Tags ------------------------
	my(@tags)  = ();
    $page->find('div#plugin-tags')->each(
        sub {
            $_->find('a')->each(sub {
				push @tags, $_->text; # yay for arrays
			});
        }
    );                                            


    # Version Requirements ------------------------
    $page->find('div.col-3')->each(
        sub {
            $min_reqs = $_->find('p')->first->text; 
        }
    );

    $last_update = $page->find('meta[itemprop="dateModified"]')->first->attr('content');

	$downloads = $page->find('meta[itemprop="interactionCount"]')->first->attr('content');


    # Ratings Summary ------------------------
    $avg_rating = $page->find('meta[itemprop="ratingValue"]')->first->attr('content');

    $rating_count = $page->find('meta[itemprop="ratingCount"]')->first->attr('content');


    # Star Ratings ------------------------
	my(@star_ratings) = ();
	$page->find('div.counter-container span.counter-count')->each(
        sub {
			push @star_ratings, $_->text;
        }
    );

    #Authors Done Properly------------------------
    my(@author)  = ();
    $page->find('div.plugin-contributor-info')->each(
        sub {
            $_->find('div > a')->each(sub {
                push @author, $_->text; # yay for arrays
            });
        }
    );

    #Authors' URL Done Properly------------------------
    my(@author_URL)  = ();
    $page->find('div.plugin-contributor-info')->each(
        sub {
            $_->find('div > a')->each(sub {
                push @author_URL, $_->attr('href'); # yay for arrays
            });
        }
    ); 

    # remove commas and quotes from strings
    # ===================================

    $plugin_name =~ s/,//g;
    $author =~ s/,//g;
    $downloads =~ s/,//g;
    $rating_count =~ s/,//g;
    $star_ratings =~ s/,//g;
    $last_update =~ s/,//g;
    $min_reqs =~ s/,//g;
    $tags =~ s/,//g;

    $plugin_name =~ s/"//g;
    $author =~ s/"//g;
    $last_update =~ s/"//g;
    $min_reqs =~ s/"//g;
    $tags =~ s/"//g;

    # Outputing...

    print "$plugin_name , $plugin_URL , ".join(" | ", @author)." , ".join(" | ", @author_URL)." , $downloads , $avg_rating , $rating_count"
        . " , ".join(", ", @star_ratings)
        . " , $last_update , $min_reqs, ".join(" | ", @tags)."\n";

    $results_handle->print("$plugin_name,$plugin_URL, ".join(" | ", @author).", ".join(" | ", @author_URL)." ,$downloads,$avg_rating,$rating_count"
        . ",".join(",", @star_ratings)
        . ",$last_update,$min_reqs,".join(" | ", @tags)."\n");

    # Logging older plugins seperately AND in main file
    # Printing it to a file later:
    # $plugins_flagged_old_handle->print($plugin_name" , "$plugin_URL" , "$old_flag);
    sleep(2);

}