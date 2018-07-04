import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import gab.opencv.*;

Kinect kinect;
boolean videoReady = false;
OpenCV opencv;

PImage flowImg;

float drag = 0.05;
float scaleVel = 0.5;
float rtnEasing = 0.05;
int maxParticles = 2000;

PImage leafImg;
PImage backGrnd;

abstract class ImagePixelProcessor {
  void processImage(PImage img, int regSizeX, int regSizeY) {
    img.loadPixels();
    for(int iy = 0; iy < img.height; iy += regSizeY) {
      for(int ix = 0; ix < img.width; ix += regSizeX) {
        boolean found = false;
        for(int iry = iy; !found && iry < min(iy + regSizeY, img.height); ++iry) {
          for(int irx = ix; !found && irx < min(ix + regSizeX, img.width); ++irx) {
            if(testPixel(img, irx, iry)) found = true;
          }
        }
        if(found) processFragment(img, ix, iy, regSizeX, regSizeY);
      }
    }  
    img.updatePixels();
  }
  
  boolean testPixel(PImage img, int x, int y) {
    return true;
  }
  abstract void processFragment(PImage img, int x1, int y1, int regSizeX, int regSizeY);
}

class ImagePixelCounter extends ImagePixelProcessor {
  int count = 0;
  int pixelCount(PImage img, int regSizeX, int regSizeY) {
    count = 0;
    processImage(img, regSizeX, regSizeY);
    return count;
  }
  
  boolean testPixel(PImage img, int x, int y) {
    color clr = img.get(x, y);
    return (alpha(clr) > 20);
  }
  void processFragment(PImage img, int x, int y, int regSizeX, int regSizeY) {
    ++count;
  }
}

class ImageFragmentList extends ImagePixelProcessor {
  IntList fragmentCoords;
  IntList getFragmentCoords(PImage img, int regSizeX, int regSizeY) {
    fragmentCoords = new IntList();
    processImage(img, regSizeX, regSizeY);
    return fragmentCoords;
  }
  
  boolean testPixel(PImage img, int x, int y) {
    color clr = img.get(x, y);
    return (alpha(clr) > 20);
  }
  void processFragment(PImage img, int x, int y, int regSizeX, int regSizeY) {
    fragmentCoords.append(x);
    fragmentCoords.append(y);
  }
}

float scrnRgnWidth;
float scrnRgnHeight;
float imgRgnWidth;
float imgRgnHeight;

class Particle {
  float posX;
  float posY;
  float orgnX;
  float orgnY;
  float texX;
  float texY;
  float velX;
  float velY;
  
  Particle(float x, float y, float tx, float ty) {
    posX = x;
    posY = y;
    orgnX = x;
    orgnY = y;
    texX = tx;
    texY = ty;
    velX = 0;
    velY = 0;
  }
  
  void draw() {
    vertex(posX, posY, texX, texY);
    vertex(posX + scrnRgnWidth, posY, texX + imgRgnWidth, texY);
    vertex(posX + scrnRgnWidth, posY + scrnRgnHeight, texX + imgRgnWidth, texY + imgRgnHeight);
    vertex(posX, posY + scrnRgnHeight, texX, texY + imgRgnHeight);
  }
  
  void update() {
    velX = velX - drag * velX;
    velY = velY - drag * velY;
    if(posX > 0 && posX < width && posY > 0 && posY < height) {
      int fgx = int(map(posX, 0, width, 0, opencv.width));
      int fgy = int(map(posY, 0, height, 0, opencv.height));
      
      PVector flowAt = opencv.getFlowAt(fgx, fgy);
      
      velX = constrain(velX + flowAt.x * scaleVel, -100, 100);
      velY = constrain(velY + flowAt.y * scaleVel, -100, 100); 
    }
    posX += velX;
    posY += velY;
    
    // Bounce the particles off the sides
    if(posX < 0) {
      posX = -posX;
      velX = -velX;
    }
    
    if(posX >= width) {
      posX = width - posX;
      velX = -velX;
    }
    
    if(posY < 0) {
      posY = -posY;
      velY = -velY;
    }
    
    if(posY >= height) {
      posY = height - posY;
      velY = -velY;
    }
    
    float velMag = mag(velX, velY);
    if(velMag < 2) {
      
      float diffX = orgnX - posX;
      float diffY = orgnY - posY;
      
      if(diffX + diffY > 4) {
        posX = posX + diffX * rtnEasing;
        posY = posY + diffY * rtnEasing;
      }
      else {
        posX = orgnX;
        posY = orgnY;
      }
    }
    if(Float.isNaN(posX) || Float.isNaN(posY)) {
      println("Bork",orgnX, orgnY);
    }
  }
}

Particle[] particleArr;

void setupParticles() {
  
  ImagePixelCounter counter = new ImagePixelCounter();
  
  int countClr = counter.pixelCount(leafImg, 1, 1);
  int ptsPerSide = floor(sqrt(float(countClr) / float(maxParticles) ));
  println(leafImg.width, leafImg.height, countClr, ptsPerSide);

  float scaleImg = scaleWithPreservedAspect(leafImg, width, height);

  imgRgnWidth = ptsPerSide;
  imgRgnHeight = ptsPerSide;
  scrnRgnWidth = ptsPerSide * scaleImg;
  scrnRgnHeight = ptsPerSide * scaleImg;
  
  ImageFragmentList fragLister = new ImageFragmentList();
  
  IntList fragList = fragLister.getFragmentCoords(leafImg, ptsPerSide, ptsPerSide);
  
  particleArr = new Particle[fragList.size() / 2];
    
  float newWidth = float(leafImg.width) * scaleImg;
  float newHeight = float(leafImg.height) * scaleImg;
  float offX = (width - newWidth) / 2;
  float offY = (height - newHeight) / 2;
  
  for(int i = 0; i < fragList.size()/2; ++i) {
    int posX = fragList.get(i * 2);
    int posY = fragList.get(i * 2 + 1);
    
    particleArr[i] = 
      new Particle(
        offX + posX*scaleImg,
        offY + posY*scaleImg,
        posX,
        posY);
  }
  
}

void drawParticles() {
  beginShape(QUADS);
  noStroke();
  texture(leafImg);
  for(Particle p: particleArr) p.draw();
  endShape();
}

void updateParticles() {
  if(!videoReady) return;
  for(Particle p: particleArr) p.update();
}

float scaleWithPreservedAspect(PImage img, int w, int h) {
  float scaleImg = float(h)/float(img.height);
  
  float newWidth = float(img.width) * scaleImg;
  if(newWidth > w) {
    scaleImg = float(w)/float(img.width);
  }
  return scaleImg;
}

void drawWithPreservedAspect(PImage img, int x, int y, int w, int h) {
  float scaleImg = scaleWithPreservedAspect(img, w, h);
  
  float newWidth = float(img.width) * scaleImg;
  float newHeight = float(img.height) * scaleImg;
  float drwX = x + (w - newWidth) / 2;
  float drwY = y + (h - newHeight) / 2;
  
  image(img, drwX, drwY, newWidth, newHeight);
}

void setup() {
  size(800, 800, P2D);
  kinect = new Kinect(this);
  kinect.initVideo();
  flowImg = createImage(kinect.width / 4, kinect.height / 4, RGB);
  opencv = new OpenCV(this, flowImg.width, flowImg.height);
  
  leafImg = loadImage("1024_KCPL_Logo-Stamp_Color_LeavesOnly.png");
  backGrnd = loadImage("1024_KCPL_Logo-Stamp_Color_NoLeaves.png");
  
  setupParticles();
    
}

void videoEvent(Kinect k) {
  flowImg.copy(
    kinect.getVideoImage(),
    0, 0,
    kinect.width, kinect.height,
    0, 0,
    flowImg.width, flowImg.height);
  opencv.loadImage(flowImg);
  opencv.flip(OpenCV.HORIZONTAL);
  opencv.calculateOpticalFlow();
  videoReady = true;
}

void draw() {
  fill(0);
  rect(0, 0, width, height);
  drawWithPreservedAspect(backGrnd, 0, 0, width, height);
  drawParticles();
  
  updateParticles();
}
