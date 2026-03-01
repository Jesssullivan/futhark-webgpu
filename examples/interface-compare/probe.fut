-- probe.fut (compatible with WebGPU backend: no f64)

entry add1_i32 (xs: []i32): []i32 =
  map (+1) xs

entry sum_f32 (xs: []f32): f32 =
  f32.sum xs

entry dot_f32 (a: []f32) (b: []f32): f32 =
  f32.sum (map2 (*) a b)

entry multi_ret (n: i32) (xs: []i32): (i32, []i32) =
  (n + 1, xs)

-- 2D input case, but with f32 (WebGPU-safe)
entry mat_row_sums_f32 (xss: [][]f32): []f32 =
  map f32.sum xss