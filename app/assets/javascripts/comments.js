var g_last_update_at = 0;
var g_timeout_n = 0;
var g_timeouts = [6, 15, 19, 30, 35, 40, 41, 42, 43, 44, 50, 60*2, 60*10, 60*20, 60*20, 60*20, 60*20, 60*60]
var g_obj_id = 0;
var g_obj_type = 'Comment';
var g_comments_updater = null;

function get_next_timeout() {
  if ( g_timeout_n < g_timeouts.length) {
     g_timeout_n++;
  }
  return g_timeouts[ g_timeout_n - 1 ];
}

function update_comments() {
  if (g_timeouts.length != g_timeout_n) {
    stop_updater();
  }
  new Ajax.Request('/comments/update_comments/',
    {     
      asynchronous: true,
      method: 'post',
      evalScripts: true,
      parameters: {since: g_last_update_at, obj_id: g_obj_id, obj_type: g_obj_type },
      onComplete: function() {
        if (g_timeouts.length != g_timeout_n || !g_comments_updater) {
          start_updater(get_next_timeout());
        } 
      }
    }
  );
}

function stop_updater() {
  if (g_comments_updater) {
    g_comments_updater.stop();
    g_comments_updater = null;
  }
}

function start_updater(period) {
  stop_updater();
  g_comments_updater = new PeriodicalExecuter(update_comments, period);
}

function reset_timeout() {
  g_timeout_n = 0;
  start_updater(10);
}

function live_comments(obj_type, obj_id) {
  g_obj_type = obj_type;
  g_obj_id = obj_id;
  start_updater(2);
}


