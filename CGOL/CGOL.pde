import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress broadcastLocation;

String ip = "127.0.0.1";
int port = 903;
int incoming_port = 12312;

int sequencerBoxesX = 10; //# of boxes along X
int sequencerBoxesY = 10; //# of boxes along Y
int sequencerSubBoxesX = 5;//# of X subboxes in a box
int sequencerSubBoxesY = 5;//# of Y subboxes in a box
int subBoxWidth = 5;
int subBoxHeight = 5;

int sizeX = sequencerBoxesX*sequencerSubBoxesX*subBoxWidth;
int sizeY = sequencerBoxesY*sequencerSubBoxesY*subBoxHeight;

int[][] multi = new int[sequencerBoxesX*sequencerSubBoxesX][sequencerBoxesY*sequencerSubBoxesY];
int[][] multinew = new int[sequencerBoxesX*sequencerSubBoxesX][sequencerBoxesY*sequencerSubBoxesY];

//Starts paused
boolean stop = true;

int currentSequencerStep = 0;
int squencerSubBoxCount = 0;
int surroundingCount = 0;

int xMain = 0;
int xMinus = 0;
int xPlus = 0;
int yMain = 0;
int yMinus = 0;
int yPlus = 0;

void setup()
{
  size(sizeX, sizeY+100);//+100 for pause button
  frameRate(6);//speed of sequencers
  
  //multi[4][4] = 1; Set up initial board programatically;
  
  oscP5 = new OscP5(this, incoming_port);
  broadcastLocation = new NetAddress(ip, port);
  sendMsg("/vol", 1);
  sendMsg("/bypass", 1);  
}


void draw()
{
  background(255,255,255);
  
  if(stop)
  {
    fill(255,0,0,255);
    rect(0,sizeY,sizeX,100);  
  }
  else{
    fill(0,255,0,255);
    rect(0,sizeY,sizeX,100);  
  }
  
  for(int x=0; x<multi.length; x++){
      for(int y=0; y<multi[x].length; y++){
        if(multi[x][y] == 1)
          {
             fill(0,0,0,255);
             rect(x*subBoxWidth,y*subBoxHeight,subBoxWidth,subBoxHeight); 
          }
      }
  }
  
  for(int z = 1; z <= sequencerBoxesX; z++)
  {
    line(sizeX*z/sequencerBoxesX, 0, sizeX*z/sequencerBoxesX, sizeY);
  }
  for(int z = 1; z <= sequencerBoxesY; z++)
  {
    line(0, sizeY*z/sequencerBoxesY, sizeX, sizeY*z/sequencerBoxesY);
  }
  
  fill(255,255,0,128);
  rect(currentSequencerStep*sizeX/sequencerBoxesX,0,sizeX/sequencerBoxesX,sizeY);
  
  if(!stop)
  {
    for(int i = 0; i <sequencerBoxesY; i ++)
    {
      for(int x=0; x<sequencerSubBoxesX; x++){
        for(int y=0; y<sequencerSubBoxesY; y++){
          if(multi[x+currentSequencerStep*sequencerSubBoxesX][y+i*sequencerSubBoxesY] == 1)
          {
            squencerSubBoxCount = squencerSubBoxCount + 1;
          }
        }
      }
      if(squencerSubBoxCount > sequencerSubBoxesX*sequencerSubBoxesY/10)
      {  
        fill(255,0,0,128);
        rect(currentSequencerStep*sizeX/sequencerBoxesX,i*sizeY/sequencerBoxesY,sizeX/sequencerBoxesX,sizeY/sequencerBoxesY);
        
        //I could not get any sound to work on Processing, but 'theoretically' this should work.
        sendMsg("/freq", currentSequencerStep*sizeX/sequencerBoxesX);
        sendMsg("/vol", i*sizeY/sequencerBoxesY);
        sendMsg("/bang", 1);
      }
      squencerSubBoxCount = 0;
    }
    
    currentSequencerStep = currentSequencerStep + 1;
    if(currentSequencerStep >= sequencerBoxesX)
    {
      currentSequencerStep = 0;
    }
    step();
  }
}

void mousePressed()
{
  if(mouseY>sizeY)
  {
    stop = !stop;
  }
  else
  {
    if(multi[mouseX/subBoxWidth][mouseY/subBoxHeight] == 0)
    {
      multi[mouseX/subBoxWidth][mouseY/subBoxHeight] = 1;
    }
    else
    {
      multi[mouseX/subBoxWidth][mouseY/subBoxHeight] = 0;
    }
  }
}

void step()
{
  for(int x=0; x<multi.length; x++){
    for(int y=0; y<multi[x].length; y++){
      surroundingCount = 0;
      
      xMain = x;
      xMinus = x-1;
      xPlus = x+1;
      //check for boarders
      if(x <= 0)
      {
        xMinus = multi.length-1;
      }
      if(x >= multi.length-1)
      {
        xPlus = 0;
      }
      
      yMain = y;
      yMinus = y-1;
      yPlus = y+1;
      //check for boarders
      if(y <= 0)
      {
        yMinus = multi[x].length-1;
      }
      if(y >= multi[x].length-1)
      {
        yPlus = 0;
      }
      
      surroundingCount = surroundingCount + multi[xMain][yMinus];
      surroundingCount = surroundingCount + multi[xMain][yPlus];
      surroundingCount = surroundingCount + multi[xMinus][yMain];
      surroundingCount = surroundingCount + multi[xMinus][yMinus];
      surroundingCount = surroundingCount + multi[xMinus][yPlus];
      surroundingCount = surroundingCount + multi[xPlus][yMain];
      surroundingCount = surroundingCount + multi[xPlus][yMinus];
      surroundingCount = surroundingCount + multi[xPlus][yPlus];

      if(surroundingCount == 2 && multi[x][y] == 1)
      {
        multinew[x][y] = 1;
      }
      else if(surroundingCount == 3)
      {
        multinew[x][y] = 1;
      }
      else
      {
        multinew[x][y] = 0;
      }
    }
  }
  for(int x=0; x<multi.length; x++){
    for(int y=0; y<multi[x].length; y++){
      multi[x][y] = multinew[x][y];
    }
  }  
    
}

void sendMsg(String label, float data)
{
   OscMessage msg = new OscMessage(label);
   msg.add(data);
   oscP5.send(msg, broadcastLocation);
}
