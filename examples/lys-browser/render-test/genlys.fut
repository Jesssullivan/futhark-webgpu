module m = import "lys"

entry init (seed: u32) (h: i32) (w: i32) =
  m.pack_state (m.init_state seed (i64.i32 h) (i64.i32 w))

entry resize
  (h: i32) (w: i32)
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32) =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  in m.pack_state (m.resize_state (i64.i32 h) (i64.i32 w) s)

entry key
  (e: i32) (key: i32)
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32) =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  let e' = if e == 0 then #keydown {key} else #keyup {key}
  in m.pack_state (m.event_state e' s)

entry mouse
  (buttons: i32) (x: i32) (y: i32)
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32) =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  in m.pack_state (m.event_state (#mouse {buttons, x, y}) s)

entry wheel
  (dx: i32) (dy: i32)
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32) =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  in m.pack_state (m.event_state (#wheel {dx, dy}) s)

entry step
  (td: f32)
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32) =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  in m.pack_state (m.event_state (#step td) s)

entry render
  (time: f32)
  (state_h: i32) (state_w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32)
  : []u32 =
  let s =
    m.unpack_state time state_h state_w center_y center_x center_object
                   moving_y moving_x mouse_y mouse_x radius paused
  in flatten (m.render_state s)

entry render_once (seed: u32) (h: i32) (w: i32): []u32 =
  let s = m.init_state seed (i64.i32 h) (i64.i32 w)
  in flatten (m.render_state s)