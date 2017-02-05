# MediaWiki-to-WordPress
MediaWiki to WordPress Converter based on http://www.analogrithems.com/rant/portfolio/mediawiki2wordpress/

I have added some very rough code to convert URLs, images (all centred), media, headers bold/italic, tables (ugly HTML), block quotes, bullents (buggy) and some maths/latex, as well asflag up (with __FIXME__) things that are noticed but not handled. You should use with caution. This code has had almost no testing.

A new option `-r` has been added to generate apache rewrite rules between old (MediaWiki) and new (WordPress) URLs.

No responsibiltiy of ruining your website, etc., you're on your own with this.

## Use
* Visit mediaiwiki-site/wiki/Special:AllPages to get a list of all pages in the CMS.
* Extract the list from the page, make into a single column, one page per line.
* Visit mediaiwiki-site/wiki/Special:Export and input the list of pages as created above.
  * Select "Include only the current revision, not the full history".
  * Select "Save as file".
  * Leave "Include templates", as you do not need them.
  * Press "Export"
* Run the converter code here, `mediawiki2wp.pl -f mediawiki.xml -o wordpress.xml`
* Import the newly created XML file into WordPress using the Importer
  * Navigate to wordpress-site/wordpress/wp-admin/admin.php?import=wordpress
  * "Choose File" and select the converted XML file
  * "Upload File and Import"
  * Assign Authors
  * Press Submit

## Tweaking
You may find that you want to use the script to generate rewrite rules from the old MediaWiki URLs, or, to print a list of where images should be located in the YYYY/MM/. The `-r` flag will help with the rewrites, but, you may need to modify the code to suit your exact needs.

If you decide to add more features, you're welcome to submit a pull request to this repository.
