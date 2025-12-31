class Tile{
  int x;
  int y;
  int n;
  Tile[] leadTo;
  int steps = -1;
  Tile leadFrom = null;
  int leadDire = 0;
  public Tile(Strategy strat, int x_, int y_, int n_){
    x = x_;
    y = y_;
    n = n_;
    strat.tileW = max(strat.tileW,x+1);
    strat.tileH = max(strat.tileH,y+1);
    int numDirections = 4;
    if (strat.useNewManeuvers) numDirections = 6;
    if (strat.useCornerManeuvers) numDirections = 8;
    leadTo = new Tile[numDirections];
    for(int t = 0; t < numDirections; t++){
      leadTo[t] = null;
    }
  }
}
