// jimbo (pure js edition)
// by joshuah@mit.edu

var imgSrc = "jimbo.jpg"

var testImg = new Image();

var ready = false;

var height = 0, width = 0;
var region = document.getElementById("region");

testImg.addEventListener('load', function () {
    ready = true;
    height = testImg.height;
    width = testImg.width;
    region.style.width = width + "px";
    for (var i = 0; i < num_splits + 1; i++) {
	divs[i].style.width = width + "px";
    }
}, false);
testImg.src = imgSrc;


function mod(x, y) {
  var result = x % y;
  if (result < 0) result += y;
  return result;
}

var num_splits = 10;

var vels = new Array();

for (var i  = 0; i < num_splits; i++) {
  vels[i] = Math.random()*20 - 10;
}


var divs = new Array();

for (var i = 0; i < num_splits + 1; i++) {
  divs[i] = document.createElement('div');
  region.appendChild(divs[i]);
  divs[i].style.width = width + "px";
}

var t = 100;
function draw() {
  setTimeout(draw, 100);
  t++;
  var yvals = new Array();
  for (var i = 0; i < num_splits; i++) {
    yvals[i] = mod(Math.floor(vels[i]*t), height);
  }
  yvals.sort(function (a,b) { return a - b; });
  
  for (var i = 0; i < num_splits + 1; i++) {
    var y1 = (i == 0 ? 0 : yvals[i-1]);
    var y2 = (i == num_splits ? height : yvals[i]);
    var h = y2 - y1;
    divs[num_splits - i].style.height = h + "px";
    divs[num_splits - i].style.background = "transparent url(" + imgSrc + ") -" + 0 + "px -" + y1 + "px no-repeat";
  }
}
draw();