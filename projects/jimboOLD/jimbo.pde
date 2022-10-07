// "jimbo", by joshuah

PImage img;
float[] vels;
int t = 0;

void setup() {
  size(482,600);
  img = loadImage("jimbo.jpg");
  
  vels = new float[10];
  for(int i = 0; i < vels.length; i++) {
    vels[i] = random(-10,10);
  }
}

void draw() {
  t++;
  int[] yvals = new int[vels.length];
  for(int i = 0; i < vels.length; i++) {
    yvals[i] = mod((int)(vels[i]*t), img.height);
  } 
  yvals = sort(yvals);

  for(int i = -1 ; i < yvals.length; i++) {
    int y1 = (i == -1 ? 0 : yvals[i]);
    int y2 = (i == yvals.length-1 ? img.height : yvals[i+1]);
    int h = y2 - y1;
    copy(img, 0, y1, img.width, h, 0, img.height-y1-h, img.width, h);
  }
}

int mod(int x, int y)
{
    int result = x % y;
    if (result < 0)
    {
        result += y;
    }
    return result;
}
