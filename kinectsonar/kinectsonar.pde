
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;

// =================================
// Sketch parameters
// Adjust these for different results
//==================================
// Clamp depth values into this range
int minDepth = 600;
int maxDepth = 1200;

int maxCircles = 100;
int circleAge = 2000; // seconds * 1000
float radiusSpeed = 10.0;


//==================================
// Kinect data
//==================================
Kinect kinect;
float angle;
boolean depthNotReady = true;
int[] depth;
PImage depthImage;
color[] depthToColorMap;

void setupKinect() {
  kinect = new Kinect(this);
  angle = kinect.getTilt();
  
  kinect.initDepth();
  kinect.enableMirror(true);
  
  depthImage = createImage(kinect.width, kinect.height, RGB);
  
  depthToColorMap = new color[2048];
  color grey = color(92,92,92);
  color blue = color(128,128,255);
  for(int i = 0; i < 2048; ++i) {
    float depth = constrain(
          float(i - minDepth) / float(maxDepth - minDepth), 
          0, 1);
    depthToColorMap[i] = lerpColor(blue, grey, depth);
  }
}

void depthEvent(Kinect k) {
  depth = k.getRawDepth();
  depthNotReady = false;
  
  depthImage.loadPixels();
  for(int i = 0; i < depth.length; ++i) {
    depthImage.pixels[i] = depthToColorMap[depth[i]];
  }
  depthImage.updatePixels();
}

//==================================
// GetScaledDepth - Returns the depth
// at the screen coordinates (x,y)
// scaled to a value between 0 and 1
//==================================
float GetScaledDepth(float x, float y) {
  // If we don't have depth data yet return 0
  if(depthNotReady)
    return 0;
  // Map the screen coordinates to the
  // kinect coordinates
  x = constrain(x, 0, width - 1);
  y = constrain(y, 0, height - 1);
  int depthPixelX = int(map(x, 0, width, 0, kinect.width));
  int depthPixelY = int(map(y, 0, height, 0, kinect.height));

  // Get the depth from the array of depths from the kinect
  // and constrain it to a min and max
  int iDepth = depth[depthPixelX + depthPixelY*kinect.width]; 
  iDepth = constrain(iDepth, minDepth, maxDepth) - minDepth; 
  
  // Scale the integer depth value to something
  // between 0 and 1
  return 1.0 - float(iDepth)/float(maxDepth - minDepth);
}

//==================================
// Circle sweep data
//==================================


class CircleSweep {
  float centerX;
  float centerY;
  float radius;
  color clr;
  int   timeOfDeath;
  boolean alive;
  
  CircleSweep(int beginTime) {
    initSweep();
    alive = false;
    timeOfDeath = millis() + beginTime;
  }

  void initSweep() {
    centerX = random(10, width - 10);
    centerY = random(10, height - 10);
    radius = 8;
    clr = color(random(0,256), 255, 255);
    timeOfDeath = millis() + circleAge;
    alive = true;
  }
  
  void update() {
    radius += radiusSpeed;
    if(timeOfDeath < millis()) {
      initSweep();
    }
  }
  
  void draw() {
    if(!alive) return;
    noStroke();
    fill(0,0,255);
    float circumference = TAU * radius;
    int divs = floor(circumference/10.0);
    float angleInc = TAU/divs;
    angle = 0;
    beginShape(QUAD_STRIP);
    texture(depthImage);
    for(int i = 0; i <= divs; ++i) {
      float x1 = centerX + cos(angle) * (radius - 2);
      float y1 = centerY + sin(angle) * (radius - 2);
      float x2 = centerX + cos(angle) * (radius + 2);
      float y2 = centerY + sin(angle) * (radius + 2);
      float tx1 = map(x1, 0, width, 0, depthImage.width);
      float ty1 = map(y1, 0, height, 0, depthImage.height);
      float tx2 = map(x2, 0, width, 0, depthImage.width);
      float ty2 = map(y2, 0, height, 0, depthImage.height);
      vertex(x1, y1, tx1, ty1);
      vertex(x2, y2, tx2, ty2);
      angle += angleInc;
    }
    endShape();
  }
}

CircleSweep[] circles;

void setupCircles() {
  circles = new CircleSweep[maxCircles];
  int beginTimeOffset = circleAge/maxCircles;
  for(int i = 0; i < maxCircles; ++i) {
    circles[i] = new CircleSweep(i * beginTimeOffset);
  }
}

void updateCircles() {
  for(int i = 0; i < maxCircles; ++i) {
    circles[i].update();
  }
}

void drawCircles() {
  for(int i = 0; i < maxCircles; ++i) {
    circles[i].draw();
  }
}

void setup() {  
  fullScreen(P2D);
  setupKinect();
  setupCircles();
}


void draw() {
  fill(0,0,0,40);
  rect(0, 0, width, height);
  
  drawCircles();
  updateCircles();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      angle++;
    } else if (keyCode == DOWN) {
      angle--;
    }
    angle = constrain(angle, 0, 30);
    kinect.setTilt(angle);
  }
}
