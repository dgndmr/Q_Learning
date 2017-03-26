class Room {

  int w, h, x, y;
  int xIndex, yIndex;
  boolean isFinish;
  boolean isVisited;
  boolean isTrap;
  boolean isPrice;
  //int visitIndex;
  int index;
  ArrayList<Room> neighbors;
  boolean showAsNeighbor;
  float qValForDebug;

  public Room(  int x, int y, int w, int h, int xIndex, int yIndex, int index, boolean isTrap, boolean isPrice ) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.xIndex = xIndex;
    this.yIndex = yIndex;
    this.index = index;
    this.isFinish = false;  
    this.isVisited = false;
    this.isTrap = isTrap;
    this.isPrice = isPrice;
    neighbors = new ArrayList<Room>();
    this.showAsNeighbor=false;
    //this.qValForDebug=-111;
  }

  void display() {

    pushStyle();

    if (isFinish)
      fill(255, 255, 0);  
    else if (isVisited)
      fill(0, 255, 0);
    else if (isTrap)
      fill(255, 124, 124);
    else if (isPrice)
      fill(0, 255, 255);
    else
      noFill();



    stroke(150);
    strokeWeight(1);  
    rect(x, y, w, h);

    fill(255);
    strokeWeight(0);  

    if (showAsNeighbor) {
      textSize(10);
      fill( 255,0,0 );
      text(qValForDebug, x+10, y+20);
    }

    popStyle();
  }
}