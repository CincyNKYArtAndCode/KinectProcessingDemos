
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

int numLines = 50;    // # lines vertically
int numLineSegs = 200; // # segments horizontally

float depthLineOffset = 40.0f;

//==================================
// Calculated once when sketch starts
//==================================
float lineSpacingY; // Y spacing between each line
float segSpacingX; // X spacing between each line

//==================================
// Inputs
//==================================
int drawOption = 1; // Controls the drawing style


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
  fullScreen(P2D);
  kinect = new Kinect(this);
  angle = kinect.getTilt();
  
  kinect.initDepth();
  kinect.enableMirror(true);

  // calulate start variables
  lineSpacingY = float(height)/(numLines + 1);
  segSpacingX = float(width)/numLineSegs;
  }

void depthEvent(Kinect k) {
  depth = k.getRawDepth();
  depthNotReady = false;
}

void drawLines(boolean randOffset) {
  //fill(0, 0, 128, 10);
  fill(0, 0, 0);
  rect(0, 0, width, height);
  stroke(255);
  strokeWeight(4);
  noFill();
  
  for(int lineNum = 0; lineNum < numLines; ++lineNum) {
    beginShape();
    for(int seg = 0; seg < numLineSegs; ++seg) {
      float ptX = seg*segSpacingX;
      float ptY = (lineNum + 1)*lineSpacingY;
      float offsetY = GetScaledDepth(ptX, ptY) * depthLineOffset;
      if(randOffset) {
        offsetY = random(0, offsetY);
      }
      vertex(ptX, ptY - offsetY);
    }
    endShape();
  }
}

int scanYPos = 0;

void drawScanLines() {
  fill(0, 0, 128, 10);
  rect(0, 0, width, height);
  stroke(255);
  strokeWeight(10);
  noFill();
  
  beginShape();
  for(int seg = 0; seg < numLineSegs; ++seg) {
    float ptX = seg*segSpacingX;
    float ptY = scanYPos;
    float offsetY = GetScaledDepth(ptX, ptY) * depthLineOffset;
    vertex(ptX, ptY - offsetY);
  }
  endShape();
  scanYPos = (scanYPos + 20) % height;
}

void drawFatLines() {
  fill(0, 0, 0);
  rect(0, 0, width, height);
  noStroke();
  fill(255,255,255);
  
  for(int lineNum = 0; lineNum < numLines; ++lineNum) {
    beginShape(QUAD_STRIP);
    for(int seg = 0; seg < numLineSegs; ++seg) {
      float ptX = seg*segSpacingX;
      float ptY = (lineNum + 1)*lineSpacingY;
      float offsetY = GetScaledDepth(ptX, ptY) * depthLineOffset/2;
      vertex(ptX, ptY - offsetY);
      vertex(ptX, ptY + offsetY);
    }
    endShape();
  }
}

void draw() {
  if(drawOption == 1 || drawOption == 2) {
    drawLines(drawOption == 2);
  }
  else if(drawOption == 3) {
    drawScanLines();
  }
  else if(drawOption == 4) {
    drawFatLines();
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
  else if(key == '1') {
    drawOption = 1;
  }
  else if(key == '2') {
    drawOption = 2;
  }
  else if(key == '3') {
    drawOption = 3;
  }
  else if(key == '4') {
    drawOption = 4;
  }
}
