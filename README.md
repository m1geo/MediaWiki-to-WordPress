# MediaWiki-to-WordPress
MediaWiki to WordPress Converter based on http://www.analogrithems.com/rant/portfolio/mediawiki2wordpress/

I have added some very rough code to convert URLs, images (all centred), media, headers bold/italic, tables (ugly HTML), block quotes, bullents (buggy) and some maths/latex, as well asflag up (with __FIXME__) things that are noticed but not handled. You should use with caution. This code has had almost no testing.

A new option `-r` has been added to generate apache rewrite rules between old (MediaWiki) and new (WordPress) URLs.

No responsibiltiy of ruining your website, etc., you're on your own with this.
