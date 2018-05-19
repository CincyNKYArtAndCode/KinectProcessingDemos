
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
int maxDepth = 900;

int totalNumOfDots = 5000;    // # dots

float maxCircleSize = 40.0f;

//==================================
// Calculated once when sketch starts
//==================================
int rows; // num of rows of dots
int cols; // num dots in a row
float rowSpacing;
float colSpacing;

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

void setup() {  
  fullScreen();
  kinect = new Kinect(this);
  angle = kinect.getTilt();
  
  kinect.initDepth();
  kinect.enableMirror(true);

  // calulate start variables
  cols = int(sqrt(totalNumOfDots * width / height));
  rows = totalNumOfDots/cols;
  
  rowSpacing = height/ float(rows + 1);
  colSpacing = width / float(cols + 1);
  
  println(rows, cols, rowSpacing, colSpacing);
}

void depthEvent(Kinect k) {
  depth = k.getRawDepth();
  depthNotReady = false;
}

void drawDepthToSize() {
  fill(0, 0, 0);
  rect(0, 0, width, height);
  noStroke();
  fill(255,255,255);
  ellipseMode(CENTER);
  
  for(int row = 0; row < rows; ++row) {
    for(int col = 0; col < cols; ++col) {
      float ptX = (col + 1)*colSpacing;
      float ptY = (row + 1)*rowSpacing;
      float circleSize = GetScaledDepth(ptX, ptY) * maxCircleSize;
      ellipse(ptX, ptY, circleSize, circleSize);
    }
  }
}

void drawDepthToJitter() {
  fill(0, 0, 0, 5);
  rect(0, 0, width, height);
  noStroke();
  ellipseMode(CENTER);
  
  for(int row = 0; row < rows; ++row) {
    for(int col = 0; col < cols; ++col) {
      float ptX = (col + 1)*colSpacing;
      float ptY = (row + 1)*rowSpacing;
      float depth = GetScaledDepth(ptX, ptY);
      if(depth > 0.05) {
        float randAngle = random(0, TAU);
        float jitterScale = random(0, depth * maxCircleSize);
        float offX = cos(randAngle) * jitterScale;
        float offY = sin(randAngle) * jitterScale;
        int minColor = int((1.0 - depth)*128.0) + 127;
        fill(random(minColor,255),random(minColor,255),random(minColor,255));
        
        ellipse(ptX + offX, ptY + offY, 8, 8);
      }
    }
  }
}


void drawDepthToCircleSize() {
  fill(0, 0, 0, 20);
  rect(0, 0, width, height);
  stroke(255);
  noFill();
  ellipseMode(CENTER);
  
  for(int row = 0; row < rows; ++row) {
    for(int col = 0; col < cols; ++col) {
      float ptX = (col + 1)*colSpacing;
      float ptY = (row + 1)*rowSpacing;
      float circleSize = GetScaledDepth(ptX, ptY) * maxCircleSize;
      ellipse(ptX, ptY, circleSize, circleSize);
    }
  }
}


void draw() {
  if(drawOption == 0)
    drawDepthToSize();
  else if(drawOption == 1)
    drawDepthToJitter();
  else if(drawOption == 2)
    drawDepthToCircleSize();
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
  else if(key == '1') {
    drawOption = 0;
  }
  else if(key == '2') {
    drawOption = 1;
  }
  else if(key == '3') {
    drawOption = 2;
  }
}
