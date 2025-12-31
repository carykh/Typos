class Button{
  int id;
  float x;
  float y;
  float w;
  float h;
  String label;
  boolean isHovered = false;
  
  public Button(int id_, float x_, float y_, float w_, float h_, String text_){
    id = id_;
    x = x_;
    y = y_;
    w = w_;
    h = h_;
    label = text_;
  }
  
  void drawButton(){
    isHovered = (mouseX >= x && mouseX < x+w && mouseY >= y && mouseY < y+h);
    
    // Button background
    noStroke();
    if(isHovered){
      fill(70, 140, 220);
    } else {
      fill(55, 115, 190);
    }
    rect(x, y, w, h, 6);
    
    // Button text
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(label, x + w/2, y + h/2);
  }
  
  boolean isClicked(float mx, float my){
    return (mx >= x && mx < x+w && my >= y && my < y+h);
  }
  
  void activate(){
    if(id == 0){
      FRAMES_PER_RUN = 1000;
    }else if(id == 1){
      FRAMES_PER_RUN = 200;
    }else if(id == 2){
      FRAMES_PER_RUN = 20;
    }else if(id == 3){
      FRAMES_PER_RUN = 3;
    }else if(id == 4){
      FRAMES_PER_RUN = 1;
      SAVE_VIDEO = false;
    }
  }
}
