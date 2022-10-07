# jimbo (coffeescript edition)
# by joshuah@mit.edu

mod = (x, y) -> ((x % y) + y) % y

ready = false
fpser = new FPSer (fps) ->
  document.getElementById("fps").innerHTML = "#{Math.floor(fps)}"

imgSrc = "512.jpg"
height = 512
width = 512
can = document.getElementById("canvas")
[can.height, can.width] = [height, width]
ctx = can.getContext('2d')
imgData = null

can.onclick = ->
  if can.style.zoom == "200%"
    can.style.zoom = "100%"
  else
    can.style.zoom = "200%"

img = new Image
img.onload = ->
    console.log "ready!"
    ready = true
    ctx.drawImage(img, 0, 0, img.width, img.height)
    imgData = ctx.getImageData(0, 0, img.width, img.height)
img.src = imgSrc

source = ((null for j in [0..height-1]) for i in [0..width-1])

steps = "L"
for i in [0..8]
  steps = steps.replace(/L/g,'+rF-lFl-Fr+')
  steps = steps.replace(/R/g,'-lF+rFr+Fl-')
  steps = steps.replace(/l/g,'L')
  steps = steps.replace(/r/g,'R')

curi = curj = curd = 0
for char in steps
  switch char
    when '+' then curd = mod(curd + 1, 4)
    when '-' then curd = mod(curd - 1, 4)
    when 'F'
      [newi, newj] = [curi, curj]
      switch curd
        when 0 then newi = curi+1
        when 1 then newj = curj+1
        when 2 then newi = curi-1
        when 3 then newj = curj-1
      source[curi][curj] = [newi, newj]
      [curi, curj] = [newi, newj]

c2i = (i, j) -> 4*(i+j*width)

t = 0
draw = ->
  setTimeout(draw, 0)
  if not ready then return

  fpser.tick()

  ci = cj = 0
  firstpixel = (imgData.data[i] for i in [0..2])
  for i in [0..(width*height)-2]
    # Slices don't work on ImageData.data. Not my fault. :-)
    [ni, nj] = source[ci][cj]
    imgData.data[c2i(ci,cj)+j] = imgData.data[c2i(ni,nj)+j] for j in [0..2]
    [ci, cj] = [ni, nj]
  imgData.data[c2i(ci,cj)+j] = firstpixel[j] for j in [0..2]
  ctx.putImageData(imgData, 0, 0)

  t++
draw()