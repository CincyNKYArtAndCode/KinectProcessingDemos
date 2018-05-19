
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;

// For kinect data
Kinect kinect;
float angle;
boolean depthNotReady = true;
int[] depth;

// =================================
// Sketch parameters
// Adjust these for different results
//==================================
// Clamp depth values into this range
int minDepth = 300;
int maxDepth = 700;

int totalCircles = 50;    
int totalCircleSegs = 100;

float circleSpeed = 20.0;
int maxCircleAge = 100;

//==================================
// Calculated once when sketch starts
//==================================

float circleCenterX[];
float circleCenterY[];
float segRadius[][];
int circleAge[];

int activeCircles = 1;

//==================================
// Inputs
//==================================
int drawOption = 0; // Controls the drawing style

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

void initCircle(int idx) {
  circleCenterX[idx] = random(10, width - 10);
  circleCenterY[idx] = random(10, height - 10);
  
  for(int segIdx = 0; segIdx < totalCircleSegs; ++segIdx) {
    segRadius[idx][segIdx] = 0f;
  }
}

void expandCircle(int idx) {
  float angleInc = TAU/float(totalCircleSegs);
  
  float angle = 0f;
  for(int segIdx = 0; segIdx < totalCircleSegs; ++segIdx) {
    float radius = segRadius[idx][segIdx];
    float offX = cos(angle) * radius;
    float offY = sin(angle) * radius;
    float depth = GetScaledDepth(circleCenterX[idx] + offX, circleCenterY[idx] + offY);
    segRadius[idx][segIdx] = radius + circleSpeed * (1.0 - depth);
    angle += angleInc;
  }
}

void drawCircle(int idx) {
  float angleInc = TAU/float(totalCircleSegs);
  
  float angle = 0f;
  beginShape();
  for(int segIdx = 0; segIdx < totalCircleSegs; ++segIdx) {
    float radius = segRadius[idx][segIdx];
    float offX = cos(angle) * radius;
    float offY = sin(angle) * radius;
    vertex(circleCenterX[idx] + offX, circleCenterY[idx] + offY);
    angle = angle + angleInc;
  }
  endShape(CLOSE);
}

void setup() {  
  fullScreen();
  kinect = new Kinect(this);
  angle = kinect.getTilt();
  
  kinect.initDepth();
  kinect.enableMirror(true);

  // calulate start variables

  circleCenterX = new float[totalCircles];
  circleCenterY = new float[totalCircles];
  segRadius = new float[totalCircles][totalCircleSegs];
  circleAge = new int[totalCircles];
  
  for(int idx = 0; idx < totalCircles; ++idx) {
    circleAge[idx] = -4 * idx;
  }
}

void depthEvent(Kinect k) {
  depth = k.getRawDepth();
  depthNotReady = false;
}

void draw() {
  fill(0,0,0,10);
  rect(0, 0, width, height);
  stroke(255);
  noFill();
  
  for(int idx = 0; idx < totalCircles; ++idx) {
    if(circleAge[idx] == 0) {
      initCircle(idx);
    }
    if(circleAge[idx] >= 0) {
      drawCircle(idx);
      expandCircle(idx);
    }
    circleAge[idx] += 1;
    if(circleAge[idx] == maxCircleAge) {
      circleAge[idx] = 0;
    }
  }
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
