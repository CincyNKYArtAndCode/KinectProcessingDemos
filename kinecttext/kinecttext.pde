import org.openkinect.freenect2.*;
import org.openkinect.processing.*;

// =================================
// Sketch parameters
// Adjust these for different results
//==================================
// Clamp depth values into this range
int minDepth = 300;
int maxDepth = 900;

int maxNumWordsToDisplay = 400;
float textSpeed = 1;
int textLifeTime = 2000; // seconds * 1000
int textFadeTime = 500; // Should be < textLifeTime
int minTextSize = 8;
int maxTextSize = 30;

//==================================
// Kinect data
//==================================
Kinect kinect;
float angle;
boolean depthNotReady = true;
int[] depth;

void setupKinect() {
  kinect = new Kinect(this);
  angle = kinect.getTilt();
  
  kinect.initDepth();
  kinect.enableMirror(true);
}

void depthEvent(Kinect k) {
  depth = k.getRawDepth();
  depthNotReady = false;
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
// Text data
//==================================

String[] lines;
int deadTextCount = 0;

class TextData {
  String theText;
  
  float posX;
  float posY;
  float velocityX;
  float velocityY;
  color textColor;
      
  int timeOfDeath;
  
  boolean alive;
  
  TextData() {
    posX = 0;
    posY = 0;
    velocityX = 0;
    velocityY = 0;
    timeOfDeath = 0;
    alive = false;
  }
  
  void initText(float x, float y) {
    int randWordIdx = floor(random(0, lines.length));
    theText = lines[randWordIdx];
    
    posX = x;
    posY = y;
    float angle = random(0, TAU);
    velocityX = cos(angle) * textSpeed;
    velocityY = sin(angle) * textSpeed;
    timeOfDeath = millis() + textLifeTime;
    textColor = color(random(0,256),255, 255);
    alive = true;
    --deadTextCount;
  }
  
  void drawText() {
    if(alive) {
      float s = constrain(float(timeOfDeath - millis())/textFadeTime, 0, 1);
      color drawColor = lerpColor(color(hue(textColor),255,0), textColor, s);
      float size = lerp(minTextSize, maxTextSize, GetScaledDepth(posX, posY)); 
      fill(drawColor);
      textAlign(CENTER, CENTER);
      textSize(size);
      text(theText, posX, posY);
    }
  }
  
  void updatePos() {
    if(alive) {
      posX += velocityX;
      posY += velocityY;
      if(timeOfDeath < millis()) {
        alive = false;
        ++deadTextCount;
      }
      
      if( GetScaledDepth(posX, posY) < 0.05) {
        timeOfDeath -= 100;
      }
    }
  }
}

TextData[] displayText;

void setupTextData() {
  displayText = new TextData[maxNumWordsToDisplay];
  for(int i = 0; i < maxNumWordsToDisplay; ++i) {
    displayText[i] = new TextData();
  }
  deadTextCount = maxNumWordsToDisplay;
}

void drawTextData() {
  for(int i = 0; i < maxNumWordsToDisplay; ++i) {
    displayText[i].drawText();
  }
}

void updateTextData() {
  for(int i = 0; i < maxNumWordsToDisplay; ++i) {
    displayText[i].updatePos();
  }
}

int deadScanPos = 0;

TextData findDeadText() {
  TextData rtn = null;
  if(deadTextCount > 0) {
    for(int i = 0; i < maxNumWordsToDisplay; ++i) {
      if(displayText[deadScanPos].alive == false) {
        rtn = displayText[deadScanPos];
        break;
      }
      deadScanPos = (deadScanPos + 1) % maxNumWordsToDisplay;
    }
  }
  return rtn;
}

//==================================
// Choose text position
//==================================

int numScanLines = 8;
int scanStart = 0;
int scanInc = 0;

int[] depthPosX;
int[] depthPosY;
int numPoints = 0;

void setupDepthScan() {
  depthPosX = new int[numScanLines * kinect.width];
  depthPosY = new int[numScanLines * kinect.width];
  scanInc = kinect.height/numScanLines;
}

void updateScan() {
  numPoints = 0;
  if(depthNotReady) return;
  for(int y = 0; y < numScanLines; ++y) {
    int depthPixelY = y*scanInc + scanStart;
    if(depthPixelY < kinect.height) {
      for(int depthPixelX = 0; depthPixelX < kinect.width; ++depthPixelX) {
        int iDepth = depth[depthPixelX + depthPixelY*kinect.width];
        if(iDepth < maxDepth) {
          depthPosX[numPoints] = depthPixelX;
          depthPosY[numPoints] = depthPixelY;
          ++numPoints;
        }
      }
    }
  }
  scanStart = (scanStart + 1) % scanInc;
}

void createRandomText() {
  if(numPoints > 0) {
    for(int i = 0; i < 8; ++i) {
      TextData td = findDeadText();
      if(td == null) break;
      
      int posIdx = floor(random(0, numPoints));
      float x = map(depthPosX[posIdx], 0, kinect.width, 0, width);
      float y = map(depthPosY[posIdx], 0, kinect.height, 0, height);
      td.initText(x, y);
    }
  }
}


void setup() {
  fullScreen();
  colorMode(HSB);
  
  lines = loadStrings("positive-words.txt");

  setupKinect();
  setupTextData();
  setupDepthScan();
}




void draw() {
  fill(0);
  rect(0, 0, width, height);
  updateTextData();
  updateScan();
  createRandomText();
  drawTextData();
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
