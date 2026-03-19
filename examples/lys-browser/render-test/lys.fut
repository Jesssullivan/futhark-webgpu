import "lib/github.com/diku-dk/lys/lys"

def rotate_point (x: f32) (y: f32) (angle: f32) =
  let s = f32.sin angle
  let c = f32.cos angle
  let xnew = x * c - y * s
  let ynew = x * s + y * c
  in (xnew, ynew)

type text_content = (i64, i64, i64, i64, i64, i64, i64)

type app_state = {
  time: f32,
  h: i64,
  w: i64,
  center: (i64, i64),
  center_object: #circle | #square,
  moving: (i64, i64),
  mouse: (i64, i64),
  radius: i64,
  paused: bool
}

def init_state (seed: u32) (h: i64) (w: i64): app_state =
  { time = 0, w, h,
    center = (h / (1 + i64.u32 seed % 11), w / (1 + i64.u32 seed % 7)),
    center_object = #circle,
    moving = (0, 0),
    mouse = (0, 0),
    radius = 20,
    paused = false
  }

def resize_state (h: i64) (w: i64) (s: app_state) =
  s with h = h with w = w

def keydown_state (key: i32) (s: app_state) =
  if key == SDLK_RIGHT then s with moving.1 = 1
  else if key == SDLK_LEFT then s with moving.1 = -1
  else if key == SDLK_UP then s with moving.0 = -1
  else if key == SDLK_DOWN then s with moving.0 = 1
  else if key == SDLK_SPACE then s with paused = !s.paused
  else if key == SDLK_c then s with center_object = #circle
  else if key == SDLK_s then s with center_object = #square
  else s

def keyup_state (key: i32) (s: app_state) =
  if key == SDLK_RIGHT then s with moving.1 = 0
  else if key == SDLK_LEFT then s with moving.1 = 0
  else if key == SDLK_UP then s with moving.0 = 0
  else if key == SDLK_DOWN then s with moving.0 = 0
  else s

def move (x: i64, y: i64) (dx, dy) = (x + dx, y + dy)
def diff (x1: i64, y1: i64) (x2, y2) = (x2 - x1, y2 - y1)

def event_state (e: event) (s: app_state) =
  match e
  case #step td ->
    s with time = s.time + (if s.paused then 0 else td)
      with center = move s.center s.moving
  case #wheel {dx = _, dy} ->
    s with radius = i64.max 0 (s.radius + i64.i32 dy)
  case #mouse {buttons, x, y} ->
    s with mouse = (i64.i32 y, i64.i32 x)
      with center =
        if buttons != 0
        then move s.center (diff s.mouse (i64.i32 y, i64.i32 x))
        else s.center
  case #keydown {key} ->
    keydown_state key s
  case #keyup {key} ->
    keyup_state key s

def render_state (s: app_state) =
  tabulate_2d s.h s.w (\i j ->
    let (i', j') =
      rotate_point
        (f32.i64 (i - s.center.0))
        (f32.i64 (j - s.center.1))
        s.time
    let r = f32.i64 s.radius
    let inside =
      match s.center_object
      case #circle -> f32.sqrt (i'**2 + j'**2) < f32.i64 s.radius
      case #square -> i' >= -r && i' < r && j' >= -r && j' < r
    in if inside then argb.white
       else if i' > j' then argb.red else argb.blue)

def text_format_state () =
  "FPS: %ld\nCenter: (%ld, %ld)\nCenter object: %[circle|square]\nRadius: %ld\nSize: (%ld,%ld)"

def text_content_state (render_duration: f32) (s: app_state): text_content =
  let center_object_id =
    match s.center_object
    case #circle -> 0
    case #square -> 1
  in (i64.f32 render_duration, s.center.0, s.center.1, center_object_id, s.radius, s.w, s.h)

def text_colour_state (_: app_state) = argb.yellow

def pack_center_object (x: #circle | #square): i32 =
  match x
  case #circle -> 0
  case #square -> 1

def unpack_center_object (x: i32): #circle | #square =
  if x == 0 then #circle else #square

def pack_bool (b: bool): i32 =
  if b then 1 else 0

def unpack_bool (x: i32): bool =
  x != 0

def pack_state (s: app_state) :
  (f32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) =
  ( s.time,
    i32.i64 s.h,
    i32.i64 s.w,
    i32.i64 s.center.0,
    i32.i64 s.center.1,
    pack_center_object s.center_object,
    i32.i64 s.moving.0,
    i32.i64 s.moving.1,
    i32.i64 s.mouse.0,
    i32.i64 s.mouse.1,
    i32.i64 s.radius,
    pack_bool s.paused
  )

def unpack_state
  (time: f32)
  (h: i32) (w: i32)
  (center_y: i32) (center_x: i32)
  (center_object: i32)
  (moving_y: i32) (moving_x: i32)
  (mouse_y: i32) (mouse_x: i32)
  (radius: i32)
  (paused: i32)
  : app_state =
  { time = time,
    h = i64.i32 h,
    w = i64.i32 w,
    center = (i64.i32 center_y, i64.i32 center_x),
    center_object = unpack_center_object center_object,
    moving = (i64.i32 moving_y, i64.i32 moving_x),
    mouse = (i64.i32 mouse_y, i64.i32 mouse_x),
    radius = i64.i32 radius,
    paused = unpack_bool paused
  }

module lys: lys with text_content = text_content = {
  type state = app_state

  def grab_mouse = false
  def init = init_state
  def resize = resize_state
  def event = event_state
  def render = render_state

  type text_content = text_content
  def text_format = text_format_state
  def text_content = text_content_state
  def text_colour = text_colour_state
}