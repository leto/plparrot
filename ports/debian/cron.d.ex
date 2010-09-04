#
# Regular cron jobs for the plparrot package
#
0 4	* * *	root	[ -x /usr/bin/plparrot_maintenance ] && /usr/bin/plparrot_maintenance
