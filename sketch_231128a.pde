//This sketch produces an animation that responds to loudness of the environment we are in
//and to the detected movement.
//Enjoy!


import ddf.minim.*;
import processing.video.*;

//backgroung
PImage img;

//ripples
int hlfWidth, hlfHeight, rippleRad, smallRippleRad, oldInd, newInd, mapInd;
int rippleMap[], ripple[];
float dst = 100;
int disturbInterval = 5500; // Initial disturb interval when it is silent in milliseconds // Time after which the disturb interval returns to the initial value
int speed1 = 2500;
int speed2 = 500;
int speed3 = 100;
int speed4 = 50;
int speed5 = 10;
int animationStartTime;
int lastDisturbTime = 0;
int rippleCounter = 0; 

//sound
Minim minim; 
AudioInput in;
int lastMeasurmentTime;
int measurmentInterval = 500;
float mean_of_loudness = 0; 
float sum_of_loudness = 0;
int nu_of_takes = 0;
AudioSample dropletSound;
int lastSoundTime = 0; 

//movement
Capture cam; 
PImage prevFrame;
int movementThreshold = 50;
int movementCount = 0;
int startTime;
int secondsCounter = 0; 
int movementInterval = 500; 


void setup() {
  size(711, 435);
  
  //background
  img = loadImage("water.jpg");
  hlfWidth = width/2;
  hlfHeight = height/2;
  
  //ripples
  rippleRad = 10; 
  smallRippleRad = 1;
  rippleMap = new int[width * (height) * 10];
  ripple = new int[width*height];
  oldInd = width;
  newInd = width * (height+7);
  ellipseMode(CENTER);
  loadPixels();
  animationStartTime = millis();
  
  //sound
  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO, 512);
  dropletSound = minim.loadSample("plop.mp3");
  
  //movement
  cam = new Capture(this, width, height);
  cam.start();
  prevFrame= createImage(width, height, RGB);
  startTime = millis();
  
  lastMeasurmentTime = millis();
  
}

void draw() {
  
  //SOUND
  //get the loudness of the environment
  sum_of_loudness += in.mix.level() * 1000; 
  nu_of_takes += 1;
  //the loudness is taken every 1500 ms
  if(millis() - lastMeasurmentTime >= measurmentInterval){
    float loudness = sum_of_loudness/nu_of_takes;
    setNewIntervalSound(loudness);
    //println(disturbInterval);
    lastMeasurmentTime = millis(); 
    sum_of_loudness = 0; 
    nu_of_takes = 0; 
  }
  
  //MOVEMENT
  if(cam.available()){
    cam.read();
    background(0);
    
    int movement = calculateMovement(cam, prevFrame);

    
    if(millis() - startTime >= movementInterval){
      println("Movement " + movement);
      startTime = millis(); 
      secondsCounter = 0;
      setIntervalMovement(movement);
    }
     secondsCounter++;
  
  }
  updateData();
  for (int i = 0; i < pixels.length; i++) {
    pixels[i] = ripple[i];
  }
  updatePixels();
  checkDisturb();
}


//function to calculate the movement before the camera
int calculateMovement(Capture currentFrame, PImage previousFrame) {
  currentFrame.loadPixels();
  previousFrame.loadPixels();
  int totalMovement = 0;

  for (int i = 0; i < currentFrame.pixels.length; i++) {
    // Extract RGB values for the current and previous frames
    color currentColor = currentFrame.pixels[i];
    color prevColor = previousFrame.pixels[i];

    // Calculate the difference between the current and previous frames
    float rDiff = red(currentColor) - red(prevColor);
    float gDiff = green(currentColor) - green(prevColor);
    float bDiff = blue(currentColor) - blue(prevColor);

    // Calculate the magnitude of the color difference
    float diffMagnitude = sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);

    // Increment the total movement if it exceeds the threshold
    if (diffMagnitude > movementThreshold) {
      totalMovement++;
    }
  }

  // Update the previous frame with the current frame
  previousFrame.copy(currentFrame, 0, 0, currentFrame.width, currentFrame.height, 0, 0, previousFrame.width, previousFrame.height);
  return totalMovement;
}

void captureEvent(Capture c) {
  c.read();
}

//change the droplet interval based on how loud it is 
void  setNewIntervalSound(float loudness){
   if (loudness < 1){
     disturbInterval = speed1;
   }
   else if (loudness >= 1 && loudness < 50){
     disturbInterval = speed2;
     
   }
   else if (loudness >= 50 && loudness < 100){
     disturbInterval = speed3;
   }
   else if (loudness >= 100 && loudness < 200){
     disturbInterval = speed4;
   }
   else{
     disturbInterval = speed5;
   }
    
}
 
//set interval with movement, only increase dont decrease
void setIntervalMovement(int movement){
  println(movement);
  if(movement > 1000 && movement <= 5000){
    if(disturbInterval > speed2){
      println("movement to speed2");
      disturbInterval = speed2;
    } 
  }
  else if(movement > 5000 && movement <= 10000){
    if(disturbInterval > speed3){
      println("movement to speed3");
      disturbInterval = speed3;
    }
  }
  else if(movement > 10000 && movement <=15000){
    if(disturbInterval > speed4){
      println("movement to speed4");
      disturbInterval = speed4;
    }
  }
  else if(movement > 15000){
    if(disturbInterval > speed5){
      println("movement to speed5");
      disturbInterval = speed5;
    }
    
  }
}

 


//updating pixels for producing the effect of the ripple
void updateData() { 
  int i = oldInd;
  oldInd = newInd;
  newInd = i;
  i = 0;
  mapInd = oldInd;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int data = (rippleMap[mapInd-width]+rippleMap[mapInd+width]+rippleMap[mapInd-1]+rippleMap[mapInd+1]) >> 1;
      data -= rippleMap[newInd+i];
      data -= data  >> 5;

      if (x == 0 || y == 0) rippleMap[newInd + i] = 0;
      else rippleMap[newInd+i] = data;

      data = 1024-data;
      int a = int((x-hlfWidth)*data/1024+hlfWidth);
      int b = int((y-hlfHeight)*data/1024+hlfHeight);

      if (a >= width) a = width-1;
      if (a < 0) a = 0;
      if (b >= height) b = height-1;
      if (b < 0) b = 0;

      ripple[i] = img.pixels[a + b * width];
      mapInd++;
      i++;
    }
  }

  
}

//see if it is soon enough to disturb
void checkDisturb() {
  int currentTime = millis();
  if (currentTime - lastDisturbTime >= disturbInterval) {
    trigerSound();
    disturbRandomPixel();
    lastDisturbTime = currentTime;
  }
}

//added sound with the droplets
void trigerSound(){
  int soundTime = millis();
  //prevents too much sound overlaping
  if(soundTime - lastSoundTime >= 150){
    dropletSound.trigger();
    lastSoundTime= soundTime;
  }
}

void disturbRandomPixel() {
  rippleCounter++;
  
  int dx = int(random(rippleRad, width - rippleRad));
  int dy = int(random(rippleRad, height - rippleRad));
  
  if(rippleCounter % 2 == 0){
    for (int j = dy - rippleRad; j < dy + rippleRad; j++) {
      for (int k = dx - rippleRad; k < dx + rippleRad; k++) {
        if (j >= 0 && j < height && k >= 0 && k < width) {
          rippleMap[oldInd + (j * width) + k] += 512;
        }
       }
   }  
  
  }
  
  else {
      for (int j = dy - smallRippleRad; j < dy + smallRippleRad; j++) {
      for (int k = dx - smallRippleRad; k < dx + smallRippleRad; k++) {
        if (j >= 0 && j < height && k >= 0 && k < width) {
          rippleMap[oldInd + (j * width) + k] += 512;
        }
       }
    }
  }
}



void stop() {
  // Close the minim object when the sketch is stopped
  minim.stop();
  super.stop();
}
