import java.util.Collections; //<>// //<>//

ArrayList<Room> roomList;
float[][] qValues;
float[][] rValues;
Mice mice;
Room lastRoom;
boolean calculated=false;
int testCounter;

float chanceToTrap=0.07;
float chanceToPrice=0.03;
boolean goOn=false;
int roomXCount;
int roomYCount;
int testRoomIndex;
float discountFactor = .95;
float learningRate = .95;

float finishReward=1000;
float coinReward;
float trapReward; 

//TODO: add prices to list
/*
*  add prices to list
 *  if not all of them collected then finish reward is zero
 *  else finish reward is 1000
 *
 */
void setup() {
  size(1200, 300);

  coinReward = finishReward /30;
  trapReward = -finishReward;

  roomList = new ArrayList<Room>();

  int roomSize = 30;
  roomXCount = width / roomSize;
  roomYCount = height / roomSize;

  int k=0;
  for (int y=0; y<roomYCount; y++ ) {
    for (int x=0; x<roomXCount; x++ ) {

      boolean isTrap = random(0, 1)<=chanceToTrap?true:false;
      boolean isPrice=false;
      if (!isTrap)
        isPrice = random(0, 1)<=chanceToPrice?true:false;

      Room r = new Room( x * roomSize, y * roomSize, roomSize, roomSize, x, y, k, isTrap, isPrice);
      roomList.add(r);
      k++;
    }
  }

  rValues = new float[roomList.size()][roomList.size()];
  qValues = new float[roomList.size()][roomList.size()];

  for (int y=0; y<roomList.size(); y++ ) {
    for (int x=0; x<roomList.size(); x++ ) {
      rValues[y][x] = -1;
      qValues[y][x] = 0;
    }
  }

  lastRoom = roomList.get(roomList.size()-1);
  lastRoom.isFinish = true;

  for (int y=0; y<roomList.size(); y++ ) {
    Room r1 = roomList.get(y);

    for (int x=0; x<roomList.size(); x++ ) {  
      Room r2 = roomList.get(x);

      if (isNeighbor( r1, r2 )) {

        if ( r2.isFinish ) {
          rValues[y][x] = finishReward;
        } else if (r2.isTrap) {
          rValues[y][x] = trapReward;
        } else if (r2.isPrice) {
          rValues[y][x] = coinReward;
        } else {
          rValues[y][x] = 0;
        }

        r1.neighbors.add(r2);
      }
    }
  }

  mice = new Mice( roomList.get(0) );
  frameRate(30);
}

void mousePressed() {
  println("mouse:" + mouseX +"-"+mouseY);

  Room r = getRoomWithXYIndex( mouseX, mouseY );
  if (r!=null) {
    for (Room n : r.neighbors) {
      n.qValForDebug = qValues[r.index][n.index];
      n.showAsNeighbor = true;
    }
  }
}

void mouseReleased() {

  Room r = getRoomWithXYIndex( mouseX, mouseY );
  if (r!=null) {
    for (Room n : r.neighbors) {
      n.showAsNeighbor = false;
    }
  }
}

Room getRoomWithXYIndex(int x, int y) {
  for (int i=0; i<roomList.size(); i++) {
    Room r = roomList.get(i);
    if (
      x > r.x && x < r.x + r.w &&
      y > r.y && y < r.y + r.h    
      ) {
      return r;
    }
  }
  return null;
}

void keyPressed() {
  goOn=!goOn;
}

void draw() {
  background(50);

  for (Room r : roomList) {
    r.display();
  }


  if (goOn) {
    if (!calculated) {
      for (int i=0; i<50; i++)
        testRoomIndex = calcQ();

      mice.activeRoom = roomList.get( testRoomIndex );
      testCounter=0;
    } else {
      if (mice.activeRoom.index != lastRoom.index) {
        testRoute();
        mice.activeRoom.isVisited = true;
        testCounter++;
        if (testCounter> roomXCount * roomYCount || !calculated) {
          clearRooms();
          calculated=false;
        }
      } else {
        clearRooms();
        calculated=false;
      }
    }
  }
}



//custom methods

void clearRooms() {
  for (int x=0; x<roomList.size(); x++ ) {
    Room r = roomList.get(x);
    r.isVisited=false;
  }
}

void testRoute() {

  Room r = mice.activeRoom;
  float maxScore=-1;
  ArrayList<Integer> maxScoredAction = new ArrayList<Integer>();

  for (int i=0; i<r.neighbors.size(); i++) {
    Room r2 = r.neighbors.get(i);
    if (!r2.isVisited) {
      if (qValues[r.index][r2.index]>maxScore ) {
        maxScore=qValues[r.index][r2.index];
        maxScoredAction.clear();
        maxScoredAction.add(r2.index);
      }
      else if(qValues[r.index][r2.index]==maxScore) {
        maxScoredAction.add(r2.index);
      }
    }
  }
  
  if(maxScoredAction.size()>0){
    mice.activeRoom = roomList.get( maxScoredAction.get(int(random( maxScoredAction.size() ))) );
  }
  else
    calculated=false;
}

int calcQ() {
  int startIndex;
  Room r;
  do {
    r = roomList.get( int(random(0, roomList.size())) );
  } while (r.isTrap || r.isFinish || r.isPrice);

  startIndex=r.index;

  do {

    if (r.neighbors.size()==0) {
      break;
    }

    Room nextActionRoom = r.neighbors.get( int(random(0, r.neighbors.size())) );

    ArrayList<Float> optimalFutureValues = new ArrayList<Float>();
    for (int x=0; x<nextActionRoom.neighbors.size(); x++ )
      optimalFutureValues.add( qValues[nextActionRoom.index][nextActionRoom.neighbors.get(x).index] );

    ArrayList<Float> oldValues = new ArrayList<Float>();
    for (int x=0; x<r.neighbors.size(); x++ )
      oldValues.add( qValues[r.index][r.neighbors.get(x).index] );

    float learned = rValues[r.index][nextActionRoom.index] + discountFactor * Collections.max(optimalFutureValues);
    float oldQ = qValues[r.index][nextActionRoom.index];
    float newQ = oldQ + learningRate * ( learned - oldQ );
    qValues[r.index][nextActionRoom.index] = newQ;

    r = nextActionRoom;
  } while (r.index != lastRoom.index);
  //normalizeQValues();


  calculated=true;
  return startIndex;
}

void normalizeQValues() {
  float max=0;
  float min=0;
  for (int y=0; y<roomYCount; y++ ) {
    for (int x=0; x<roomXCount; x++ ) {
      if (qValues[y][x]>max)
        max = qValues[y][x];
      else if (qValues[y][x]<min)
        min = qValues[y][x];
    }
  }
  println(min +"-"+max);
  for (int y=0; y<roomYCount; y++ ) {
    for (int x=0; x<roomXCount; x++ ) {
      qValues[y][x] = map(qValues[y][x], min, max, trapReward, finishReward);
    }
  }
}

boolean isNeighbor(Room r1, Room r2) {
  float subX = abs(r1.xIndex - r2.xIndex);
  float subY = abs(r1.yIndex - r2.yIndex);
  if ((subX == 1 || subX == 0) && ( subY == 1 || subY==0 ) && 
    !(subX == 0 && subY == 0) && !(subX == 1 && subY == 1) ) 
    return true;
  else
    return false;
}