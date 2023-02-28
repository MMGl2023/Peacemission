SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=artem.voroztsov@gmail.com
HOME=/home/webmaster
ROOT=/home/webmaster/mmgl/branches/v2.0

*/5 * * * *  webmaster $ROOT/script/restart_if_off  >> $ROOT/log/restarting.log 2>&1
30 5 * * *  webmaster $ROOT/script/clear_sessions  >> $ROOT/log/restarting.log 2>&1
*/30 * * * * webmaster rm -rf $ROOT/tmp/*.lock
20 3 * * * webmaster rm -rf $ROOT/tmp/cache/rozysk.org/*
30 4 * * * webmaster rm -rf $ROOT/tmp/cache/views/*
40 3 * * * webmaster rm -rf $ROOT/public/i/*
30 5 * * * root tail -10000 $ROOT/log/production.log 2>&1 | grep Error | grep -v RoutingError | egrep -v '$^'
04 5 * * * root /etc/init.d/httpd restart 2>&1 | grep -v "sorry, you must have a tty" | grep -v "[warn]" | egrep -v '$^'
