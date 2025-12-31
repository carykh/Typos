import java.util.Map;

import java.util.Dictionary;
import java.util.Enumeration;
import java.util.Hashtable;

String VIDEO_FILENAME = "typo_video_blah.mp4";
boolean SAVE_VIDEO = true;
boolean ONLY_SAVE_FINAL_PATH_FRAMES = false;

int N = 400;
int BUCKET_MAX = 50;
int[] PRESET_PATH = null;

String[] strat_codes = {"RECT-1.0","DIAM-1.0","OCT-1.0","CIR-1.0","OS-0.6667","SOS-0.6667"};
// All 6 shapes: Square, Diamond, Octagon, Circle, Obsidian Spear, Sharpened Obsidian Spear

color[] colors =
// Bright colors for dark theme - 6 colors for 6 shapes
{color(120, 200, 80), color(255, 160, 50), color(180, 100, 255), color(80, 180, 220), color(255, 100, 120), color(220, 200, 80)};



int runs = 0;
int FRAMES_PER_RUN = 200;
int framesSinceLast = 0;
float prog = 0;
PImage crown;
Dictionary<String, String> names = new Hashtable<>();

Strategy[] strats_old = new Strategy[strat_codes.length];
Strategy[] strats_corner = new Strategy[strat_codes.length];
Strategy[] strats = strats_corner; // default to corner for newest features
int[] path_chosen;
Button[] buttons;

void setup(){
  size(1920,1080);
  
  // Initialize buttons AFTER size() so height is correct
  // Position buttons in a vertical stack on the right side
  float btnW = 120;
  float btnH = 40;
  float btnX = width - btnW - 20;
  float btnStartY = height - 260;
  float btnGap = 50;
  buttons = new Button[]{
    new Button(0, btnX, btnStartY, btnW, btnH, "Slow"),
    new Button(1, btnX, btnStartY + btnGap, btnW, btnH, "Medium"),
    new Button(2, btnX, btnStartY + btnGap * 2, btnW, btnH, "Fast"),
    new Button(3, btnX, btnStartY + btnGap * 3, btnW, btnH, "Instant"),
    new Button(4, btnX, btnStartY + btnGap * 4, btnW, btnH, "No Record")
  };
  names.put("RECT-3.0,NOM","Banger Tweet (No Maneuvers)");
  names.put("RECT-3.0","Banger Tweet");
  names.put("RECT-1.0","Square");
  names.put("RECT-1.0,NOM","Square");
  names.put("RECT-1.2,JGD-4-2-0.73","Wide Square (25% sus ends)");
  names.put("RECT-1.5,JGD-1-0-1.00","Wide Square (Oops! All sus ends)");
  names.put("RECT-1.5,HOL-4-2-4","Wide Square (With holes/tabs)");
  names.put("DIAM-1.0","45-deg rotated square (\"Diamond\")");
  names.put("DIAM-1.0,NOM","45-deg rotated square (\"Diamond\")");
  names.put("OS-0.6667","Obsidian Spear");
  names.put("SOS-0.6667","Sharpened Obsidian Spear");
  names.put("OCT-1.0","Octagon");
  names.put("CIR-1.0","Circle");
  
  crown = loadImage("crown.png");
  path_chosen = newPath();
  for(int s = 0; s < strat_codes.length; s++){
    strats_old[s] = new Strategy(strat_codes[s], strats_old, s, false, false);
    strats_corner[s] = new Strategy(strat_codes[s], strats_corner, s, true, true);
    strats_old[s].pathfind(path_chosen);
    strats_corner[s].pathfind(path_chosen);
  }
}
void draw(){
  // In instant mode, run multiple pathfinds per frame for speed
  int runsPerFrame = (FRAMES_PER_RUN <= 3) ? 100 : 1;
  
  for(int r = 0; r < runsPerFrame; r++){
    if(framesSinceLast >= FRAMES_PER_RUN){
      setNewPaths();
      framesSinceLast = 0;
      runs++;
    }
    framesSinceLast++;
  }
  
  prog = (framesSinceLast+0.5)/FRAMES_PER_RUN*3;
  
  background(30, 32, 38);
  
  // Layout constants - 6 shapes in each row
  float headerH = 28;
  float stratW = width / 6.0;
  float stratH = 240;  // Reduced height for strategy cells
  float rowGap = 8;
  float sidePad = 8;
  
  // Only draw detailed visualizations in non-instant mode
  boolean instantMode = (FRAMES_PER_RUN <= 3);
  
  if(!instantMode){
    // Draw section headers with subtle background
    noStroke();
    fill(45, 48, 55);
    rect(0, 0, width, headerH);
    rect(0, headerH + stratH + rowGap, width, headerH);
    
    fill(180, 185, 200);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("OLD MANEUVERS (4 directions)", width/2, headerH/2);
    text("CORNER MANEUVERS (8 directions - with corner teleport)", width/2, headerH + stratH + rowGap + headerH/2);
    
    // Draw old maneuvers (top row) - 6 shapes
    float oldY = headerH + 3;
    for(int s = 0; s < strat_codes.length; s++){
      strats_old[s].drawStrat(s * stratW + sidePad, oldY, stratW - sidePad * 2, stratH - 6);
    }
    
    // Draw corner maneuvers (second row) - 6 shapes
    float cornerY = headerH + stratH + rowGap + headerH + 3;
    for(int s = 0; s < strat_codes.length; s++){
      strats_corner[s].drawStrat(s * stratW + sidePad, cornerY, stratW - sidePad * 2, stratH - 6);
    }
    
    // Graph area - positioned to avoid button overlap
    float graphY = cornerY + stratH + 12;
    float graphH = height - graphY - 15;
    float graphRightMargin = 180;  // Leave room for buttons on right
    drawGraph(80, graphY, width - graphRightMargin - 80, graphH - 10);
  } else {
    // In instant mode, just draw the graph full-size
    drawGraph(80, 60, width - 260, height - 160);
  }
  
  drawButtons();
  
  if(ONLY_SAVE_FINAL_PATH_FRAMES){
    if(framesSinceLast >= FRAMES_PER_RUN){
      for(int s = 0; s < 5; s++){
      }
    }
  }else{
    if(SAVE_VIDEO && FRAMES_PER_RUN >= 3){
    }
  }
}
int getUnit(int m, float max_ratio){
  int[] units = {1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000};
  for(int u = 0; u < units.length; u++){
    if(units[u] > m*max_ratio){
      return units[u];
    }
  }
  return 1;
}

String commafy(int n){
  String stri = n+"";
  String result = "";
  for(int i = 0; i < stri.length(); i++){
    if(i >= 1 && (stri.length()-i)%3 == 0){
      result += ",";
    }
    result += stri.charAt(i);
  }
  return result;
}

void drawGraph(float x, float y, float w, float h){
  // Graph background
  noStroke();
  fill(40, 44, 52);
  rect(x - 10, y - 10, w + 20, h + 40, 8);
  
  strokeWeight(1);
  stroke(60, 65, 75);
  fill(100, 105, 115);
  textAlign(CENTER, TOP);
  textSize(16);
  int horiz_unit = getUnit(BUCKET_MAX, 0.05);
  for(int b = 0; b < BUCKET_MAX; b+=horiz_unit){
    float line_x = x+w*(float)b/BUCKET_MAX;
    line(line_x,y,line_x,y+h);
    text(b,line_x,y+h+6);
  }
  int max = 0;
  for(int s = 0; s < strat_codes.length; s++){
    max = max(max,strats_old[s].getBucketMax());
    max = max(max,strats_corner[s].getBucketMax());
  }
  int vert_unit = getUnit(max, 0.2);
  textAlign(RIGHT, CENTER);
  for(int u = 0; u < max; u += vert_unit){
    float line_y = y+h-h*((float)u/max);
    line(x,line_y,x+w,line_y);
    text(commafy(u),x-8,line_y);
  }
  
  // Draw old maneuvers (solid lines)
  for(int s = 0; s < strat_codes.length; s++){
    stroke(colors[s]);
    for(int b = 0; b < BUCKET_MAX-1; b++){
      float x1 = x+w*(float)b/BUCKET_MAX;
      float x2 = x+w*(float)(b+1)/BUCKET_MAX;
      float y1 = y+h-h*((float)strats_old[s].buckets[b]/max);
      float y2 = y+h-h*((float)strats_old[s].buckets[b+1]/max);
      strokeWeight(3);
      line(x1,y1,x2,y2);
    }
    strokeWeight(3);
    float avg = strats_old[s].data[0];
    float x_avg = x+w*avg/BUCKET_MAX;
    float y_avg = y+h-h*getFloatValue(strats_old[s].buckets,avg)/max;
    dottedLine(x_avg,y_avg,x_avg,y+h,20,1.61803*s);
  }

  // Draw corner maneuvers (dashed lines)
  for(int s = 0; s < strat_codes.length; s++){
    stroke(colors[s]);
    for(int b = 0; b < BUCKET_MAX-1; b++){
      float x1 = x+w*(float)b/BUCKET_MAX;
      float x2 = x+w*(float)(b+1)/BUCKET_MAX;
      float y1 = y+h-h*((float)strats_corner[s].buckets[b]/max);
      float y2 = y+h-h*((float)strats_corner[s].buckets[b+1]/max);
      strokeWeight(2);
      // Draw dashed line
      float dashLength = 8;
      float totalDist = dist(x1, y1, x2, y2);
      int numDashes = ceil(totalDist / (dashLength * 2));
      for(int d = 0; d < numDashes; d += 2){
        float startT = (float)d / numDashes;
        float endT = min((float)(d+1) / numDashes, 1.0);
        float dx1 = lerp(x1, x2, startT);
        float dy1 = lerp(y1, y2, startT);
        float dx2 = lerp(x1, x2, endT);
        float dy2 = lerp(y1, y2, endT);
        line(dx1, dy1, dx2, dy2);
      }
    }
    strokeWeight(2);
    float avg = strats_corner[s].data[0];
    float x_avg = x+w*avg/BUCKET_MAX;
    float y_avg = y+h-h*getFloatValue(strats_corner[s].buckets,avg)/max;
    // Draw dashed average line
    dottedLine(x_avg,y_avg,x_avg,y+h,12,1.61803*s + 0.25);
  }
  
  // Sample count - positioned in top-left of graph to avoid button overlap
  textSize(22);
  textAlign(LEFT, TOP);
  fill(200, 205, 215);
  text("N = "+commafy(runs), x + 10, y + 10);
}
void dottedLine(float x1, float y1, float x2, float y2, float size, float offset){
  float dist_ = dist(x1,y1,x2,y2);
  int pieces = ceil(dist_/size);
  for(int p = -2; p < pieces+2; p+=2){
    
    float start_prog = min(max((p-offset%2.0)*size/dist_,0),1);
    float end_prog = min(max((p+1-offset%2.0)*size/dist_,0),1);
    float x_a = lerp(x1,x2,start_prog);
    float y_a = lerp(y1,y2,start_prog);
    float x_b = lerp(x1,x2,end_prog);
    float y_b = lerp(y1,y2,end_prog);
    line(x_a,y_a,x_b,y_b);
  }
}
float getFloatValue(int[] arr, float index){
  int i = (int)index;
  float before = arr[min(max(i,0),arr.length-1)];
  float after = arr[min(max(i+1,0),arr.length-1)];
  return before + (after-before)*(index%1.0);
}
void drawButtons(){
  for(int b = 0; b < buttons.length; b++){
    buttons[b].drawButton();
  }
}
void setNewPaths(){
  path_chosen = newPath();
  for(int s = 0; s < strat_codes.length; s++){
    strats_old[s].pathfind(path_chosen);
    strats_corner[s].pathfind(path_chosen);
  }
}
int[] ringAroundTheDiamond(){
  int C = 421;
  int R = 14;
  int runs_mod = runs%(R*8);
  int[] select = new int[R*4];
  for(int r = 0; r < R; r++){
    select[r] = (r+1)*(r+1)-1;
    select[R*1+r] = C-(R-r)*(R-r)-1;
    select[R*2+r] = C-(r+1)*(r+1);
    select[R*3+r] = (R-r)*(R-r);
  }
  int[] s = {0,0};
  if(runs_mod < R*2){
    s[0] = R*3;
    s[1] = runs_mod;
  }else if(runs_mod < R*4){
    s[0] = (R*3+runs_mod-R*2)%(R*4);
    s[1] = R*2;
  }else if(runs_mod < R*6){
    s[0] = R*1;
    s[1] = (runs_mod-R*4)+R*2;
  }else if(runs_mod < R*8){
    s[0] = (R*1+runs_mod-R*6)%(R*4);
    s[1] = 0;
  }
  
  int[] result = {select[s[0]],select[s[1]]};
  
  return result;
}

int[] newPath(){
  //return ringAroundTheDiamond();
  
  if(PRESET_PATH != null){
    return PRESET_PATH;
  }
  int[] result = {0,0};
  result[0] = (int)random(0,N);
  do{
    result[1] = (int)random(0,N);
  }while(result[1] == result[0]);
  return result;
}

void mousePressed(){
  for(int b = 0; b < buttons.length; b++){
    if(buttons[b].isClicked(mouseX,mouseY)){
      buttons[b].activate();
    }
  }
}
