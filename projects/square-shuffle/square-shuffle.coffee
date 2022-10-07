window.addEventListener "load", ->
  mod = (x, y) -> ((x % y) + y) % y

  """
  func_concat = (seq) ->
    (x) -> (if seq.length then seq[0](func_concat(seq.slice(1))(x)) else x)
  """

  func_concat = (seq) ->
    (x) ->
      for i in [seq.length-1 ... -1]
        x = seq[i](x)
      return x

  """
  func_concat = (seq) ->
    (x) -> (if seq.length then func_concat(seq.slice(0, seq.length-1))(seq[seq.length-1](x))
  """

  hstack = (seq, spacing=0) ->
    # TODO: general library for 2D arrays

  class SquareShuffler
    constructor: (@perm, @icon) ->

    @concat: (seq) ->
      new SquareShuffler func_concat(s.perm for s in seq),
                         hstack((s.icon for s in seq), 1)

    @transpose: (shuffler) ->
      flip = ([i, j]) -> [j, i]
      new SquareShuffler ((pt) -> flip shuffler.perm flip pt), null # TODO flip icon

  # here are some nice shufflers!
  swirl = (ni, nj, r) ->
    a = {'00':[0,1], '01':[1,0], '11':[0,-1], '10':[-1,0]}
    b = {'00':[1,0], '10':[0,1], '11':[-1,0], '01':[0,-1]}
    perm = ([i, j]) ->
      [di, dj] = (if r then a else b)["" + mod(i+ni,2) + mod(j+nj,2)]
      return [i+di, j+dj]
    return new SquareShuffler perm, null
  translate = (di, dj) -> new SquareShuffler (([i,j]) -> [i+di,j+dj]), null
  rows = (seq) -> new SquareShuffler (([i,j]) -> [i,j+seq[mod(i,seq.length)]]), null
  cols = (seq) -> new SquareShuffler.transpose rows seq
  sit = () -> new SquareShuffler ((x) -> x), null
  zigzag = (ni, nj) ->
    a = {'00':[0,1], '01':[1,-1], '11':[1,-1], '10':[0,1]}
    perm = ([i, j]) ->
      [di, dj] = a["" + mod(i+ni,2) + mod(j+nj,2)]
      return [i+di, j+dj]
    return new SquareShuffler perm, null

  seq = [SquareShuffler.concat([translate(1,0), swirl(0,0,false)]),
         rows([-1,1]),
         SquareShuffler.concat([translate(0,1), swirl(0,1,true)]),
         cols([-1,1]),
         SquareShuffler.concat([translate(-1,0), swirl(1,1,false)]),
         rows([1,-1]),
         swirl(0,0,true),
         cols([1,2]),
         SquareShuffler.concat([translate(0,-1), swirl(1,0,true)]),
         cols([1,-1]),
         swirl(1,1,true),
         rows([1,2])]

  seq2 = [rows([-1,1]),
         cols([-1,1]),
         rows([1,-1]),
         cols([1,2]),
         cols([1,-1]),
         rows([1,2])]


  sign = (a) -> if a > 0 then 1 else -1
  root = (a) -> sign(a) * Math.pow(Math.abs(a), 0.8)
  sigmoid = (a) -> (root(2*a-1)+1)/2

  last_press = 0
  period = 1000 # milliseconds
  rawSize = 100
  mul = 100

  #colors = np.random.randint(0, 256, size=(100,100,3)) # TODO

  colors = (((Math.random()*256 for c in [0...3]) for i in [0...100]) for j in [0...100])
  offsetM = 50
  offsetN = 50

  canvas = document.getElementById("canvas")
  context = canvas.getContext('2d')

  draw = () ->
    if not canvas
      requestAnimationFrame draw
      return

    now = Date.now()

    retime = (now-last_press)/period
    o = sigmoid(mod(retime, 1))
    t = Math.floor(retime)

    bg_l = 50 + 50 * Math.cos(now/1000)
    context.fillStyle = "hsl(0,0%,#{bg_l}%)"
    context.fillRect 0, 0, canvas.width, canvas.height
    
    rawSpacing = 180+20*Math.cos(now/500)

    size = rawSize * mul / 100
    spacing = rawSpacing * mul / 100

    cur = seq[mod(t, seq.length)]

    halfM = Math.min(Math.ceil(canvas.width/spacing+2), offsetM-3)
    halfN = Math.min(Math.ceil(canvas.height/spacing+2), offsetN-3)
    for i in [offsetM-halfM..offsetM+halfM]
      for j in [offsetN-halfN..offsetN+halfN]
        if true #mul > 20
          [di, dj] = cur.perm([i,j])
        else
          [di, dj] = cur.perm([Math.floor(i/2),Math.floor(j/2)])
          di = di * 2 + i%2
          dj = dj * 2 + j%2
        x = spacing * ((1-o)*i + o*di - offsetM) + canvas.width/2
        #x += (spacing-size) * ((1-o)*(1-i%2) + o*(1-di%2)) * (1-Math.max(0, mul-20)/80)
        y = spacing * ((1-o)*j + o*dj - offsetN) + canvas.height/2
        #y += (spacing-size) * ((1-o)*(1-j%2) + o*(1-dj%2)) * (1-Math.max(0, mul-20)/80)
        color = [0, 0, 0]
        for c in [0...3]
          color[c] = Math.floor((1-o)*colors[i][j][c] + o*colors[di][dj][c])
        #color = [255, 255, 255]
        context.fillStyle = "rgb(#{color[0]},#{color[1]},#{color[2]})"
        context.fillRect 10+x, 10+y, size, size

    requestAnimationFrame draw
    return
  #setInterval draw, 10
  requestAnimationFrame draw
  #draw()

  onResize = () ->
    canvas = document.getElementById("canvas")
    if canvas
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
  window.addEventListener('resize', onResize)
  onResize()

  onZoom = (e) ->
    e = window.event || e
    delta = Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail)))
    mul = Math.max(mul + delta, 1)
    console.log mul
  canvas.addEventListener('mousewheel', onZoom)
  canvas.addEventListener('DOMMouseScroll', onZoom)
