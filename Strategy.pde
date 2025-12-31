class Strategy {
  String s;
  int id;
  ArrayList<Tile> tiles;
  int tileW, tileH;
  Tile cursor_curr;
  Tile cursor_next;
  ArrayList<Tile> path;
  int strat_max_steps;
  int[][] dires = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}, {0, 0}, {0, 0}, {0, 0}, {0, 0}};
  Strategy[] array;
  float[] data = {0, 0};
  int[] buckets;

  boolean useNewManeuvers;
  boolean useCornerManeuvers;
  public Strategy(String s_, Strategy[] array_, int id_, boolean useNewManeuvers_, boolean useCornerManeuvers_) {
    id = id_;
    s = s_;
    array = array_;
    useNewManeuvers = useNewManeuvers_;
    useCornerManeuvers = useCornerManeuvers_;
    tileW = 0;
    tileH = 0;
    tiles = new ArrayList<Tile>(0);
    buckets = new int[BUCKET_MAX];
    for (int b = 0; b < BUCKET_MAX; b++) {
      buckets[b] = 0;
    }
    int[] dims = getMinimumDims();
    int W = dims[0];
    int H = dims[1];

    Tile[][] map = clearMap(s, W, H);
    for (int x = 0; x < W; x++) {
      for (int y = 0; y < H; y++) {
        Tile thisTile = map[x][y];
        if (thisTile == null) {
          continue;
        }
        for (int dire = 0; dire < 4; dire++) {
          int dx = x+dires[dire][0];
          int dy = y+dires[dire][1];
          if (inBounds(dx, dy, W, H) && map[dx][dy] != null) {
            thisTile.leadTo[dire] = map[dx][dy];
          }
        }
      }
    }
    if (noManeuvers()) { // naive strats that don't loop over
      return;
    }
    // left-right loopover
    for (int n = 0; n < tiles.size()-1; n++) {
      Tile tile1 = tiles.get(n);
      Tile tile2 = tiles.get(n+1);
      tile1.leadTo[1] = tile2;
      tile2.leadTo[0] = tile1;
    }
    // top-bottom clip to the extremes
    for (int x = 0; x < W; x++) {
      Tile topTile = map[x][0];
      if (topTile != null && topTile.n >= 1) {
        topTile.leadTo[2] = tiles.get(0);
      }
      Tile bottomTile = map[x][H-1];
      if (bottomTile != null && bottomTile.n < tiles.size()-1) {
        bottomTile.leadTo[3] = tiles.get(tiles.size()-1);
      }
    }
    // up-down into a gap
    for (int x = 0; x < W; x++) {
      for (int y = 0; y < H; y++) {
        Tile thisTile = map[x][y];
        if (thisTile == null) {
          continue;
        }
        if (y >= 1 && map[x][y-1] == null) {
          int dx = findClosestHorizontalValid(map, x, y-1, W, H);
          if (dx >= 0) {
            thisTile.leadTo[2] = map[dx][y-1];
          }
        }
        if (y < H-1 && map[x][y+1] == null) {
          int dx = findClosestHorizontalValid(map, x, y+1, W, H);
          if (dx >= 0) {
            thisTile.leadTo[3] = map[dx][y+1];
          }
        }
      }
    }
    if (useNewManeuvers) {
      // row navigation: connect to start and end of current row
      for (int y = 0; y < H; y++) {
        Tile rowStart = null;
        Tile rowEnd = null;
        // find leftmost and rightmost tiles in this row
        for (int x = 0; x < W; x++) {
          if (map[x][y] != null) {
            if (rowStart == null) rowStart = map[x][y];
            rowEnd = map[x][y];
          }
        }
        // connect all tiles in row to row start and end
        if (rowStart != null && rowEnd != null) {
          for (int x = 0; x < W; x++) {
            Tile thisTile = map[x][y];
            if (thisTile != null) {
              if (thisTile != rowStart) {
                thisTile.leadTo[4] = rowStart; // go to row start
              }
              if (thisTile != rowEnd) {
                thisTile.leadTo[5] = rowEnd; // go to row end
              }
            }
          }
        }
      }
    }
    if (useCornerManeuvers) {
      // corner navigation: connect all tiles to top-left and bottom-right corners
      Tile topLeftCorner = tiles.get(0); // first tile is top-left
      Tile bottomRightCorner = tiles.get(tiles.size() - 1); // last tile is bottom-right
      for (int n = 0; n < tiles.size(); n++) {
        Tile thisTile = tiles.get(n);
        if (thisTile != topLeftCorner) {
          thisTile.leadTo[6] = topLeftCorner; // go to top-left corner
        }
        if (thisTile != bottomRightCorner) {
          thisTile.leadTo[7] = bottomRightCorner; // go to bottom-right corner
        }
      }
    }
  }

  boolean noManeuvers() {
    String[] parts = s.split(",");
    for (int p = 0; p < parts.length; p++) {
      if (parts[p].equals("NOM")) {
        return true;
      }
    }
    return false;
  }

  int getWidthFromHeight(int h) {
    String[] parts = s.split(",");
    float aspect_ratio = Float.parseFloat(parts[0].split("-")[1]);
    String shapeType = parts[0].split("-")[0];
    if(shapeType.equals("OS") || shapeType.equals("SOS")){
      return round(aspect_ratio*h*h);
    }
    return round(aspect_ratio*h);
  }

  int[] getMinimumDims() {
    int H = getMinimumSize();
    int[] result = {getWidthFromHeight(H), H};
    return result;
  }
  int getMinimumSize() {
    for (int a = 0; a < N; a++) {
      int count = 0;
      int W = getWidthFromHeight(a);
      int H = a;
      for (int x = 0; x < W; x++) {
        for (int y = 0; y < H; y++) {
          if (valid(s, x, y, W, H)) {
            count++;
          }
        }
      }
      if (count >= N) {
        return a;
      }
    }
    return -1;
  }

  int getBucketMax() {
    int record2 = 0;
    for (int b = 0; b < BUCKET_MAX; b++) {
      if (buckets[b] > record2) {
        record2 = buckets[b];
      }
    }
    return record2;
  }

  int findClosestHorizontalValid(Tile[][] map, int x, int y, int W, int H) {
    for (int dist = 1; dist < H; dist++) {
      for (int sign = -1; sign <= 1; sign += 2) {
        int dx = x+dist*sign;
        if (inBounds(dx, y, W, H) && map[dx][y] != null) {
          return dx;
        }
      }
    }
    return -1;
  }

  boolean shapeValid(String shape, int x, int y, int w, int h) {
    float EPS = 0.00000001;
    if (shape.equals("RECT")) {
      return true;
    } else if (shape.equals("DIAM")) {
      int n = (w-1)/2;
      int taxicab_dist = abs(x-n)+abs(y-n);
      return (taxicab_dist <= n);
    } else if (shape.equals("OS")) {
      return ((float)x/w < (1.0-(float)y/h)+EPS);
    } else if (shape.equals("SOS")) {
      return ((float)x/w < pow(1.0-(float)y/h, 2)+EPS);
    } else if (shape.equals("OCT")) {
      int n = (w-1)/2;
      int taxicab_dist = abs(x-n)+abs(y-n);
      return (taxicab_dist <= n*1.5);
    } else if (shape.equals("CIR")) {
      float n = (w-1)/2;
      float dist_ = dist(x, y, n, n);
      return (dist_ <= n);
    }
    return false;
  }

  String getShape() {
    String[] parts = s.split(",");
    return parts[0].split("-")[0];
  }

  boolean valid(String s, int x, int y, int w, int h) {
    boolean inShape = shapeValid(getShape(), x, y, w, h);
    if (!inShape) {
      return false;
    }
    String[] parts = s.split(",");
    for (int p = 1; p < parts.length; p++) {
      String[] ruleParts = parts[p].split("-");
      if (ruleParts.length < 4) {
        continue;
      }
      String ruleType = ruleParts[0];
      int ruleEvery = Integer.parseInt(ruleParts[1]);
      int ruleOffset = Integer.parseInt(ruleParts[2]);
      float ruleLength = Float.parseFloat(ruleParts[3]);
      if (y%ruleEvery == ruleOffset) {
        if (ruleType.equals("JGD")) { // jagged
          float frac = 1-((y/4)*0.618033)%1.0; // golden ratio
          if ((float)x/w >= ruleLength*frac) { // past the sus end
            return false;
          }
        } else if (ruleType.equals("HOL")) { // holes (tabs) in the region
          if (x%round(ruleLength) != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  int getDiag(int n) {
    int rad = 1;
    boolean found = false;
    while (!found) {
      if (rad*(rad+1)*2+1 >= n) {
        found = true;
        return rad;
      }
      rad++;
    }
    return 1;
  }

  int getSpear(int n) {
    int rad = 1;
    boolean found = false;
    while (!found) {
      if (rad*rad*(rad+1)/2 >= n) {
        found = true;
        return rad;
      }
      rad++;
    }
    return 1;
  }

  boolean inBounds(int x, int y, int w, int h) {
    return (x >= 0 && x < w && y >= 0 && y < h);
  }

  Tile[][] clearMap(String s, int W, int H) {
    Tile[][] result = new Tile[W][H];

    int n = 0;
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) {
        if (!valid(s, x, y, W, H)) {
          result[x][y] = null;
        } else {
          result[x][y] = new Tile(this, x, y, n);
          tiles.add(result[x][y]);
          n++;
        }
      }
    }
    return result;
  }

  void drawStrat(float scrX, float scrY, float scrW, float scrH) {
    // Layout: title at top, grid in center, stats+keypad at bottom
    float titleH = 22;
    float bottomH = 55;  // Reduced bottom area
    float gridH = scrH - titleH - bottomH - 8;
    float gridY = scrY + titleH + 4;
    
    float midX = scrX + scrW / 2;
    float midY = gridY + gridH / 2;
    float MARGIN = 2;
    // Scale to fit within bounds with padding
    float scaleVal = min((scrW - 16) / (tileW + MARGIN), (gridH - 8) / (tileH + MARGIN));
    float weight = min(1, scaleVal / 30);

    // Draw title - truncate more aggressively for narrow columns
    fill(colors[id]);
    textAlign(CENTER, TOP);
    textSize(15);
    String stratName = names.get(s);
    int maxChars = (int)(scrW / 8);  // Adaptive truncation based on width
    if (stratName != null && stratName.length() > maxChars) {
      stratName = stratName.substring(0, maxChars - 3) + "...";
    }
    text(stratName != null ? stratName : s, scrX + scrW / 2, scrY + 2);

    // Draw grid - centered in the grid area
    pushMatrix();
    translate(midX - tileW / 2 * scaleVal, midY - tileH / 2 * scaleVal);
    for (int n = 0; n < tiles.size(); n++) {
      float surge_factor = 0;
      Tile tile = tiles.get(n);
      float x = tile.x;
      float y = tile.y;
      if (tile == cursor_next) {
        fill(0, 255, 100);
      } else if (tile == cursor_curr) {
        fill(255, 60, 60);
      } else {
        float self_prog = (float) tile.steps / strat_max_steps;
        if (abs(prog - self_prog) < 0.2) {
          surge_factor = 0.5 + 0.5 * cos(abs(prog - self_prog) / 0.2 * PI);
        }
        color c = color(60, 70, 90);
        if (prog >= self_prog) {
          float light = 200 - 15 * (tile.steps - 1);
          c = color(light, light, light);
        }
        fill(colorLerp(c, color(255, 255, 255), surge_factor * 1.0));
      }
      stroke(surge_factor * 0.8 * 255);
      strokeWeight(2 * weight);
      pushMatrix();
      translate(x * scaleVal, y * scaleVal);
      scale(1 + surge_factor * 0.3);
      rect(-0.5 * scaleVal, -0.5 * scaleVal, scaleVal, scaleVal);
      popMatrix();
    }
    float pathProg = min(min(prog - 1, 1) * (getLongestPath(array, 1) - 1), path.size() - 1);
    if (prog >= 1.0) {
      float base_thickness = min(max(scaleVal * 0.6, 10), 20);
      drawPath(scaleVal, base_thickness * min(max(0, prog - 1.0), 0.2));
      drawExplorer(scaleVal, pathProg);
    }
    popMatrix();
    
    // Bottom area: keypad on left side, stats on right
    float bottomY = scrY + scrH - bottomH;
    
    // Keypad positioned on the left portion
    drawKeyPad(scrX, bottomY, scrW * 0.55, bottomH, pathProg);
    
    // Crown and step count on the right side
    float rightX = scrX + scrW * 0.55;
    fill(colors[id]);
    textSize(28);
    textAlign(LEFT, TOP);
    if (prog >= 1.0) {
      if (pathProg >= path.size() - 1 && getLongestPath(array, -1) == path.size()) {
        image(crown, rightX, bottomY + 2, 28, 28);
      }
      text((int) pathProg, rightX + 32, bottomY + 2);
    }
    
    // Stats below step count
    fill(140, 145, 155);
    textSize(11);
    textAlign(LEFT, TOP);
    text("Avg:" + nf(data[0], 0, 2), rightX, bottomY + 32);
    text("Std:" + nf(data[1], 0, 2), rightX + scrW * 0.22, bottomY + 32);
  }
  void drawKeyPad(float scrX, float scrY, float scrW, float scrH, float pathProg) {
    // Compact keypad layout: arrow keys in center, extras on sides
    // Positions relative to center: [xOffset, yOffset] in grid units
    float[][] places = {{0, 0.5}, {2, 0.5}, {1, -0.5}, {1, 0.5}, {-1, 0.5}, {3, 0.5}, {-1, -0.5}, {3, 1.5}};
    float R = min(scrW / 5.5, 32);  // Adaptive size based on available width
    float keyPadX = scrX + R * 1.5;  // Start from left with small margin
    float keyPadY = scrY + scrH / 2;  // Center vertically
    int numDirs = useCornerManeuvers ? 8 : (useNewManeuvers ? 6 : 4);
    for (int dire = 0; dire < numDirs; dire++) {
      pushMatrix();
      translate(keyPadX + R * places[dire][0], keyPadY + R * places[dire][1]);
      drawKey(0, 0, R * 0.72, R * 0.72, dire, pathProg);
      popMatrix();
    }
  }
  void drawKey(float x, float y, float w, float h, int dire, float pathProg) {
    float[] rots = {2, 0, 3, 1, 0, 0}; // added placeholders for directions 4,5
    pushMatrix();
    translate(x + w / 2, y + h / 2);
    if (dire < 4) {
      rotate(rots[dire] * PI / 2);
    }
    fill(65, 70, 80);

    int piece = max(0, path.size() - 2 - (int) pathProg);
    float pathProg_piece = pathProg % 1.0;
    if (pathProg >= 0 && piece >= 0 && piece < path.size() - 1) {
      Tile t1 = path.get(piece);
      if (t1.leadDire == dire) {
        fill(40, 180, 80);
        scale(1.2 - 0.2 * abs(pathProg_piece - 0.5) / 0.5);
      }
    }
    stroke(90, 95, 105);
    strokeWeight(2);
    rect(-w / 2, -h / 2, w, h, 4);
    stroke(200, 205, 215);
    strokeWeight(2);

    if (dire == 4) {
      // double left arrow for "go to row start"
      line(-w * 0.3, 0, w * 0.1, 0);
      line(-w * 0.3, 0, -w * 0.15, w * 0.15);
      line(-w * 0.3, 0, -w * 0.15, -w * 0.15);
      line(-w * 0.05, 0, w * 0.1, 0);
      line(-w * 0.05, 0, w * 0.05, w * 0.15);
      line(-w * 0.05, 0, w * 0.05, -w * 0.15);
    } else if (dire == 5) {
      // double right arrow for "go to row end"
      line(w * 0.3, 0, -w * 0.1, 0);
      line(w * 0.3, 0, w * 0.15, w * 0.15);
      line(w * 0.3, 0, w * 0.15, -w * 0.15);
      line(w * 0.05, 0, -w * 0.1, 0);
      line(w * 0.05, 0, -w * 0.05, w * 0.15);
      line(w * 0.05, 0, -w * 0.05, -w * 0.15);
    } else if (dire == 6) {
      // diagonal arrow to top-left corner
      line(-w * 0.25, -w * 0.25, w * 0.2, w * 0.2);
      line(-w * 0.25, -w * 0.25, -w * 0.25, -w * 0.05);
      line(-w * 0.25, -w * 0.25, -w * 0.05, -w * 0.25);
      // small box in corner to indicate "corner"
      noFill();
      rect(-w * 0.35, -w * 0.35, w * 0.15, w * 0.15);
    } else if (dire == 7) {
      // diagonal arrow to bottom-right corner
      line(w * 0.25, w * 0.25, -w * 0.2, -w * 0.2);
      line(w * 0.25, w * 0.25, w * 0.25, w * 0.05);
      line(w * 0.25, w * 0.25, w * 0.05, w * 0.25);
      // small box in corner to indicate "corner"
      noFill();
      rect(w * 0.2, w * 0.2, w * 0.15, w * 0.15);
    } else {
      // regular directional arrows
      line(-w * 0.35, 0, w * 0.35, 0);
      line(w * 0.15, w * 0.2, w * 0.35, 0);
      line(w * 0.15, -w * 0.2, w * 0.35, 0);
    }
    popMatrix();
  }
  int getLongestPath(Strategy[] array, int sign) {
    int record2 = 0;
    if (sign == -1) {
      record2 = -999999999;
    }
    for (int s = 0; s < array.length; s++) {
      if (array[s].path.size()*sign > record2) {
        record2 = array[s].path.size()*sign;
      }
    }
    return record2*sign;
  }

  void drawPath(float scale, float thickness) {
    for (int n = 0; n < path.size()-1; n++) {
      Tile thisTile = path.get(n);
      int dire = thisTile.leadDire;
      float x1 = thisTile.x;
      float y1 = thisTile.y;
      float x2 = path.get(n+1).x;
      float y2 = path.get(n+1).y;

      float[] c1 = {x1*scale, y1*scale};
      float[] c2 = {x2*scale, y2*scale};
      if (dire <= 1 && y1 != y2) {
        drawArrow(c1, dire, scale*0.2, thickness, scale);
        drawArrow(dire, c2, scale*0.2, thickness, scale);
      } else {
        drawArrow(c1, c2, scale*0.2, thickness);
      }
    }
  }
  void drawExplorer(float scale, float pathProg) {
    float pathProg_piece = pathProg%1.0;
    int piece = max(0, path.size()-1-(int)pathProg);
    Tile t1 = path.get(piece);
    Tile t2 = path.get(max(0, piece-1));

    float x = lerp(t1.x, t2.x, pathProg_piece);
    float y = lerp(t1.y, t2.y, pathProg_piece);

    if (t2.leadDire == 0 && t1.y > t2.y) {
      if (pathProg_piece >= 0.5) {
        x = t2.x+1-pathProg_piece;
        y = t2.y;
      } else {
        x = t1.x-pathProg_piece;
        y = t1.y;
      }
    }
    if (t2.leadDire == 1 && t1.y < t2.y) {
      if (pathProg_piece >= 0.5) {
        x = t2.x-1+pathProg_piece;
        y = t2.y;
      } else {
        x = t1.x+pathProg_piece;
        y = t1.y;
      }
    }
    pushMatrix();
    translate(x*scale, y*scale);
    fill(0, 100, 255);
    stroke(0);
    strokeWeight(3);
    ellipse(0, 0, scale*0.4, scale*0.4);
    popMatrix();
  }
  color colorLerp(color a, color b, float x) {
    float newR = red(a)+(red(b)-red(a))*x;
    float newG = green(a)+(green(b)-green(a))*x;
    float newB = blue(a)+(blue(b)-blue(a))*x;
    return color(newR, newG, newB);
  }

  void pathfind(int[] path_chosen) {
    path = new ArrayList<Tile>(0);
    cursor_curr = tiles.get(path_chosen[0]);
    cursor_next = tiles.get(path_chosen[1]);
    for (int n = 0; n < tiles.size(); n++) {
      tiles.get(n).steps = 9999999;
    }
    cursor_curr.steps = 0;

    ArrayList<Tile> queue = new ArrayList<Tile>(0);
    queue.add(cursor_curr);
    while (queue.size() >= 1) {
      Tile t = queue.get(0);
      //for (int dire = 0; dire < t.leadTo.length; dire++) {
      for (int dire = t.leadTo.length-1; dire >= 0; dire--) {
        Tile next = t.leadTo[dire];
        if (next != null && next.steps == 9999999) {
          next.leadFrom = t;
          next.leadDire = dire;
          next.steps = t.steps+1;
          queue.add(next);
        }
      }
      queue.remove(0);
    }



    //search(cursor_curr, 0);
    strat_max_steps = 0;
    for (int n = 0; n < tiles.size(); n++) {
      strat_max_steps = max(strat_max_steps, tiles.get(n).steps);
    }
    Tile path_head = cursor_next;
    while (path_head != cursor_curr) {
      path.add(path_head);
      path_head = path_head.leadFrom;
    }
    path.add(cursor_curr);
    buckets[path.size()-1] += 1;
    calculateData();
  }

  void calculateData() {
    int summer = 0;
    int counter = 0;
    for (int b = 0; b < BUCKET_MAX; b++) {
      summer += b*buckets[b];
      counter += buckets[b];
    }
    float mean = (float)summer/counter;
    int stddev = 0;
    for (int b = 0; b < BUCKET_MAX; b++) {
      stddev += pow(b-mean, 2)*buckets[b];
    }
    data[0] = mean;
    data[1] = sqrt((float)stddev/counter);
  }


  /*void search(Tile cursor, int step_level) {
   cursor.steps = step_level;
   for (int dire = 0; dire < cursor.leadTo.length; dire++) {
   Tile next = cursor.leadTo[dire];
   if (next != null && next.steps > step_level) {
   next.leadFrom = cursor;
   next.leadDire = dire;
   search(next, step_level+1);
   }
   }
   }*/

  void drawArrow(int dire, float[] c1, float ARROW_R, float thickness, float scale) {
    float[] c2 = {c1[0]+dires[dire][0]*scale, c1[1]+dires[dire][1]*scale};
    drawArrow(c2, c1, ARROW_R, thickness);
  }

  void drawArrow(float[] c2, int dire, float ARROW_R, float thickness, float scale) {
    int[][] dires = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}, {0, 0}, {0, 0}};
    float[] c1 = {c2[0]-dires[dire][0]*scale, c2[1]-dires[dire][1]*scale};
    drawArrow(c2, c1, ARROW_R, thickness);
  }

  void drawArrow(float[] c2, float[] c1, float ARROW_R, float thickness) {
    float _dist = d(c1, c2);
    float angle = atan2(c2[1]-c1[1], c2[0]-c1[0]);
    strokeWeight(thickness);
    stroke(255, 0, 0);
    pushMatrix();
    translate(c1[0], c1[1]);
    rotate(angle);

    line(0, 0, _dist, 0);
    line(_dist, 0, _dist-ARROW_R, ARROW_R);
    line(_dist, 0, _dist-ARROW_R, -ARROW_R);
    popMatrix();
  }

  float d(float[] c1, float[] c2) {
    return dist(c1[0], c1[1], c2[0], c2[1]);
  }
}
