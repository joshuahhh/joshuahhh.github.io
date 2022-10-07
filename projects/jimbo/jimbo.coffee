# jimbo (coffeescript edition)
# by joshuah@mit.edu

mod = (x, y) -> ((x % y) + y) % y

imgSrc = "jimbo.jpg"
ready = false
height = 0
width = 0
region = document.getElementById "region"

numSplits = 10

vels = (Math.random()*20 - 10 for i in [0..numSplits-1])
divs = (document.createElement('div') for i in [0..numSplits])
region.appendChild(div) for div in divs

window.testImg = new Image
window.testImg.addEventListener 'load', ->
  ready = true
  height = testImg.height
  width = testImg.width
  region.style.width = "#{width}px"
  div.style.width = "#{width}px" for div in divs
window.testImg.src = imgSrc

t = 100
draw = ->
  setTimeout draw, 100
  if not ready then return

  yvals = (mod(Math.floor(vels[i]*t), height) for i in [0..numSplits-1])
          .sort (a,b) -> a-b
  for i in [0..numSplits]
    y1 = if i==0         then 0      else yvals[i-1]
    y2 = if i==numSplits then height else yvals[i]
    h = y2 - y1
    divs[numSplits - i].style.height = h + "px"
    divs[numSplits - i].style.background = "
      transparent url(#{imgSrc}) -0px -#{y1}px no-repeat"

  t++

draw()