import oscP5.*;
import netP5.*;
import java.util.Random;

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
int lives = 2;
int type = 0;//0=Normal 1=Permanent 2=Permanent blank spot
int splash = 0;//0=No Splash 1=Random 2=Inverse(B/W) 3=Random+RandomColor
int radius = 5;//Radius for Splash

int currentSequencerStep = 0;
int squencerSubBoxCount = 0;
int surroundingCount = 0;

int xMain = 0;
int xMinus = 0;
int xPlus = 0;
int yMain = 0;
int yMinus = 0;
int yPlus = 0;

Random rand = new Random();

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
    fill(0,0,0,255);
    rect(0,sizeY,sizeX/2,100);  
  }
  else{
    fill(255,255,255,255);
    rect(0,sizeY,sizeX/2,100);  
  }
  if(splash == 0)
  {
    fill(0,255,255,255);
    rect(sizeX/2,sizeY,3*sizeX/4,100);  
  }
  else if(splash == 1)
  {
    fill(255,0,255,255);
    rect(sizeX/2,sizeY,3*sizeX/4,100);
  }
  else if(splash == 2)
  {
    fill(0,0,255,255);
    rect(sizeX/2,sizeY,3*sizeX/4,100);
  }
  else if(splash == 3)
  {
    fill(255,0,255,255);
    rect(sizeX/2,sizeY,3*sizeX/4,100);
  }
  if(type == 0)
  {
    fill(255,255,255,255);
    rect(3*sizeX/4,sizeY,sizeX,100); 
  }
  else if(type == 1)
  {
    fill(255,0,0,255);
    rect(3*sizeX/4,sizeY,sizeX,100); 
  }
  else if(type == 2)
  {
    fill(0,255,0,255);
    rect(3*sizeX/4,sizeY,sizeX,100); 
  }
  
  
  for(int x=0; x<multi.length; x++){
      for(int y=0; y<multi[x].length; y++){
        //Normal
        if(multi[x][y] > 0)
        {
          fill(0,0,0,255);
          rect(x*subBoxWidth,y*subBoxHeight,subBoxWidth,subBoxHeight);
        }
        //permanent
        if(multi[x][y] == -1)
        {
          fill(255,0,0,255);
          rect(x*subBoxWidth,y*subBoxHeight,subBoxWidth,subBoxHeight);
        }
        //permanent blank spot
        if(multi[x][y] == -2)
        {
          fill(0,255,0,255);
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
          if(multi[x+currentSequencerStep*sequencerSubBoxesX][y+i*sequencerSubBoxesY] > 0 || multi[x+currentSequencerStep*sequencerSubBoxesX][y+i*sequencerSubBoxesY] == -1)
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
    if(mouseX<=sizeX/2)
    {
      stop = !stop;
    }
    if(mouseX<=3*sizeX/4)
    {
      splash = (splash+1)%4;
    }
    else
    {
      type = (type+1)%3;
    }
  }
  else
  {
    if(splash == 0)
    {
      if(multi[mouseX/subBoxWidth][mouseY/subBoxHeight] == 0)
      {
        if(type == 0)
        {
          multi[mouseX/subBoxWidth][mouseY/subBoxHeight] = 1;
          multinew[mouseX/subBoxWidth][mouseY/subBoxHeight] = 1;
        }
        else
        {
          multi[mouseX/subBoxWidth][mouseY/subBoxHeight] = -1*type;
          multinew[mouseX/subBoxWidth][mouseY/subBoxHeight] = -1*type;
        }
      }
      else
      {
        multi[mouseX/subBoxWidth][mouseY/subBoxHeight] = 0;
        multinew[mouseX/subBoxWidth][mouseY/subBoxHeight] = 0;
      }
    }
    else if(splash == 1)
    {
      int currX = mouseX/subBoxWidth;
      int currY = mouseY/subBoxHeight;
      
      for(int x = (-1*radius); x < radius; x++)
      {
        for(int y = (-1*radius); y < radius; y++)
        {
          if(rand.nextDouble()>.5)
          {
            if(type == 0)
            {
              multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
              multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
            }
            else
            {
              multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1*type;
              multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1*type;
            }
          }
          else
          {
            //Omitting the next 2 lines might make it cooler
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
          }
        }
      }
    }
    else if(splash == 2)
    {
      int currX = mouseX/subBoxWidth;
      int currY = mouseY/subBoxHeight;
      
      for(int x = (-1*radius); x < radius; x++)
      {
        for(int y = (-1*radius); y < radius; y++)
        {
          if(multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] == 0)
          {
            if(type == 0)
            {
              multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
              multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
            }
            else
            {
              multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1*type;
              multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1*type;
            }
          }
          else
          {
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
          }
        }
      }
    }
    else if(splash == 3)
    {
      int currX = mouseX/subBoxWidth;
      int currY = mouseY/subBoxHeight;
      
      for(int x = (-1*radius); x < radius; x++)
      {
        for(int y = (-1*radius); y < radius; y++)
        {
          double ran = rand.nextDouble();
          if(ran<.25)
          {
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 0;
          }
          else if(ran<.5)
          {
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = 1;
          }
          else if(ran<.75)
          {
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -1;
          }
          else if(ran<=1)
          {
            multi[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -2;
            multinew[abs((currX+x)%(sequencerBoxesX*sequencerSubBoxesX))][abs((currY+y)%(sequencerBoxesY*sequencerSubBoxesY))] = -2;
          }
        }
      } 
    }
  }
}

void step()
{
  for(int x=0; x<multi.length; x++){
    for(int y=0; y<multi[x].length; y++){
      if(multi[x][y] >= 0)
      {
        surroundingCount = 0;
      
        xMain = x;
        xMinus = abs((x-1)%(sequencerBoxesX*sequencerSubBoxesX));
        xPlus = (x+1)%(sequencerBoxesX*sequencerSubBoxesX);
      
        yMain = y;
        yMinus = abs((y-1)%(sequencerBoxesY*sequencerSubBoxesY));
        yPlus = (y+1)%(sequencerBoxesY*sequencerSubBoxesY);
      
        if(multi[xMain][yMinus] > 0 || multi[xMain][yMinus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xMain][yPlus] > 0 || multi[xMain][yPlus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xMinus][yMain] > 0 || multi[xMinus][yMain] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xMinus][yMinus] > 0 || multi[xMinus][yMinus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xMinus][yPlus] > 0 || multi[xMinus][yPlus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xPlus][yMain] > 0 || multi[xPlus][yMain] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xPlus][yMinus] > 0 || multi[xPlus][yMinus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        if(multi[xPlus][yPlus] > 0 || multi[xPlus][yPlus] == -1)
        {
          surroundingCount = surroundingCount + 1;
        }
        
        if(surroundingCount == 2 && multi[x][y] > 0)
        {
          multinew[x][y] = multi[x][y] + 1;
        }
        else if(surroundingCount == 3)
        {
          multinew[x][y] = multi[x][y] + 1;
        }
        else
        {
          if(multi[x][y] != 0)
          {
            multinew[x][y] = multi[x][y] - 1;
          }
        }
        if(multinew[x][y] > lives)
        {
           multinew[x][y] = lives;
        }
      }
      else
      {
        multinew[x][y] = multi[x][y];
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
