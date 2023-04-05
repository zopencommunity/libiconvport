# z/OS Tagging Patch

This patch will tag the output stream / file with the correct CCSID, 
but only on z/OS.

This requires a change to iconv.c and there is a corresponding unit 
test provided to validate that the tagging is correctly performed.
