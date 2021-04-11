// Individual holds the parameters, rating, parents and can draw itself 

class Individual implements Comparable {
  float[] parameters = {};
  float rating; 
  int id;
  int[] parents = {};
  
  int[][][] values = new int[256][0][2];
  int[][] vertexes = new int[0][2];
  float[][] lineCoords = new float[0][2];
  
  float scaleFactor;
  
  Individual(int pid) {
    id = pid;
    rating = defaultRating;
    
    // Each defines its own parameters and decide what to do with them
    // parameter 0: cellWidth 3 to 40
    // parameter 1: cellHeight 3 to 40
    // parameter 2: minBrightness 0 to 255
    // parameter 3: maxBrightness 1 to 255
    // parameter 4: maxLength 0 to 300
    // parameter 5: minStrokeDarkness 1 to 255
    // parameter 6: maxStrokeDarkness 50 to 255
    // parameter 7: minStrokeWeight 0 to 5
    // parameter 8: maxStrokeWeight 0 to 5
    // parameter 9: curveTightness -5 to 5
    
    // TODO: ADD
      // Total number of strokes to use
    
    parameters = new float[11];
    for (int i = 0; i < parameters.length; i++) {
      parameters[i] = random(1);
    } 
    
    scaleFactor = 1;
  }
  
  void mutate(float probability){
    // mutation is a gausian perterbation/nudge 
    for (int i = 0; i < parameters.length; i++) {
      if (random(1) < probability){
        float offset = randomGaussian()/6;
        if (random(1)<.5) offset = 0 - offset;
        parameters[i] = min(max(parameters[i]+offset,0),1);
      }
    }
  }
  
  void draw(PGraphics canvas, int cx, int cy, int width, int height, float strokeScale){
    // First calculate the lines
    //println("drawing stage 1");
    int cellWidth =  (int) map (parameters[0], 0, 1, 2, 40);
    int cellHeight =  (int) map (parameters[1], 0, 1, 2, 40);
    int numberCells = floor(image.width / cellWidth);
    int numberRows = floor(image.height / cellHeight);
    //println("number of columns and rows: "+numberCells+numberRows);
    // determin the brightness for each reagion (pixelate)
    for (int x=cellWidth/2; x<numberCells*cellWidth; x+=cellWidth){
      for (int y=cellHeight/2; y<numberRows*cellHeight; y+=cellHeight){
        int brightness=0;
        int sampleSize=0;
        for (int samplex = x - cellWidth/2; samplex < x + cellWidth/2; samplex++){
          for (int sampley = y - cellHeight/2; sampley < y + cellHeight/2; sampley++){
            brightness+=brightness(image.pixels[sampley*image.width+samplex]);
            sampleSize++;
          }
        }
        if(sampleSize>0) brightness = brightness/sampleSize;
        
        values[brightness]=(int[][])append(values[brightness], new int[] {(int) (x),(int) (y)});
      }
    }
    
    //println("drawing stage 2");
    int first = -1;
    int[] latest = {};
    
    int minBrightness =  (int) map (min(parameters[0], parameters[1]), 0, 1, 0, 255);
    int maxBrightness =  max(minBrightness+1, (int) map (max(parameters[0], parameters[1]), 0, 1, 0, 255));
    
    //print("minBrightness pixel used:" + minBrightness);
    //println(" maxBrightness pixel used:" + maxBrightness);
    
    // create vertexes based on each brightness level
    for (int b = minBrightness; b<maxBrightness; b++){
      if (values[b].length>0){
        // first pick a random cell
        if (first<0){
          first = int(random(values[b].length));
          latest = values[b][first];
          vertexes = (int[][])append(vertexes, new int[] {values[b][first][0], values[b][first][1]});
        }
        
        // remove it
        values[b] = slice(values[b], first);
        
        while (values[b].length>0){
          int closestindex=0;
          float closestdistance=10000;
          for(int v=0;v<values[b].length;v++){
            //float distance = sqrt(pow(latest[0]-values[b][v][0], 2)+pow(latest[1]-values[b][v][1], 2));
            float distance = distanceBetween2Points(latest, values[b][v]);
            if (distance<closestdistance){
              closestdistance = distance;
              closestindex = v;
            }
          }
          
          latest = values[b][closestindex]; 
          vertexes = (int[][])append(vertexes, new int[] {values[b][closestindex][0], values[b][closestindex][1]});
       
          // remove it
          values[b] = slice(values[b], closestindex);
        }
      }
    }
    //println("drawing stage 3");
    int curveTightness = (int) map (parameters[0], 0, 1, -5, 5);
    lineCoords = curvesToPoints(vertexes, curveTightness, cp5.getController("resolution").getValue());
    
    //println("drawing stage 4");
    // Actually draw it
    float minDistance = height;
    float maxDistance = 0;
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<minDistance) minDistance=distance;
      if (distance>maxDistance) maxDistance=distance;
    }
    
    int maxLength = (int) map (parameters[4], 0, 1, 1, 300);
    int minStrokeDarkness = (int) map (min(parameters[5], parameters[6]), 0, 1, 1, 255);
    int maxStrokeDarkness = (int) map (max(parameters[5], parameters[6]), 0, 1, 20, 255);
    float minStrokeWeight = (strokeScale * map (min(parameters[7], parameters[8]), 0, 1, 0, 5));
    float maxStrokeWeight = (strokeScale * map (max(parameters[7], parameters[8]), 0, 1, .5, 5));
  
    //print("maxLength:" + maxLength);
    //print(" minStrokeDarkness:" + minStrokeDarkness);
    //print(" maxStrokeDarkness:" + maxStrokeDarkness);
    //print(" minStrokeWeight:" + minStrokeWeight);
    //println(" maxStrokeWeight:" + maxStrokeWeight);
    
    // modifiers to support scalling 
    float scallingValue = 1;
    if (image.width>image.height){
      scallingValue = (float) width / image.width;
    } else { 
      scallingValue = (float) height / image.height;
    }
    float topLeftX = cx - image.width*scallingValue/2;
    float topLeftY = cy - image.height*scallingValue/2;
    
    //println("drawing stage 5");
    
    canvas.fill(255);
    canvas.noStroke();
    canvas.beginDraw();
    canvas.rect(0, 0, canvas.height, canvas.height);
    noFill();
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<maxLength){
        float invertDistance = map(distance, minDistance, maxDistance, 1, 0);
        canvas.stroke(0, map(invertDistance, 0, 1, minStrokeDarkness, maxStrokeDarkness));
        canvas.strokeWeight( map(invertDistance, 0, 1, minStrokeWeight, maxStrokeWeight));
        canvas.strokeCap(SQUARE);
        canvas.line(topLeftX + lineCoords[l][0] * scallingValue, topLeftY + lineCoords[l][1] * scallingValue, topLeftX + lineCoords[l+1][0] * scallingValue, topLeftY + lineCoords[l+1][1] * scallingValue);
      }
    }
    canvas.endDraw();
    //println("drawing done");
    //println("--------------------------");
  }
  
  void rate(float r){
    rating = r;
  }
  
  public String[] getSVG(String[] FileOutput, int cx, int cy){
    String rowTemp;
    
    float minDistance = height;
    float maxDistance = 0;
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<minDistance) minDistance=distance;
      if (distance>maxDistance) maxDistance=distance;
    }
    
    int maxLength = (int) map (parameters[4], 0, 1, 1, 300);
    int minStrokeDarkness = (int) map (min(parameters[5], parameters[6]), 0, 1, 1, 255);
    int maxStrokeDarkness = (int) map (max(parameters[5], parameters[6]), 0, 1, 20, 255);
    int minStrokeWeight = (int) map (min(parameters[7], parameters[8]), 0, 1, 0, 5);
    int maxStrokeWeight = (int) map (max(parameters[7], parameters[8]), 0, 1, .5, 5);
    
    // modifiers to support scalling 
    float scallingValue = 1;
    if (image.width>image.height){
      scallingValue = (float) width / image.width;
    } else { 
      scallingValue = (float) height / image.height;
    }
    //float topLeftX = cx - image.width*scallingValue/2;
    //float topLeftY = cy - image.height*scallingValue/2;
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<maxLength){
        float invertDistance = map(distance, minDistance, maxDistance, 1, 0);
        float strokeOpacity = map (invertDistance, 0, 1, minStrokeDarkness/255.0, maxStrokeDarkness/255.0);
        rowTemp = "<path style=\"fill:none;stroke:black;stroke-opacity:"+ strokeOpacity +";stroke-width:"+map(invertDistance, 0, 1, minStrokeWeight, maxStrokeWeight)+"px;stroke-linejoin:round;stroke-linecap:butt;\" d=\"M "; 
        
        FileOutput = append(FileOutput, rowTemp);
        
        rowTemp = (lineCoords[l][0] * scallingValue) + " " + (lineCoords[l][1] * scallingValue) + "\r";
        FileOutput = append(FileOutput, rowTemp);
        
        rowTemp = (lineCoords[l+1][0] * scallingValue) + " " + (lineCoords[l+1][1] * scallingValue) + "\r";
        FileOutput = append(FileOutput, rowTemp);
        
        FileOutput = append(FileOutput, "\" />"); // End path description
      }
    }
    return FileOutput;
  }
  
  public String[] getEggbotSVG(String[] FileOutput, int cx, int cy){
    String rowTemp;
    
    float minDistance = height;
    float maxDistance = 0;
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<minDistance) minDistance=distance;
      if (distance>maxDistance) maxDistance=distance;
    }
    int maxLength = (int) map (parameters[4], 0, 1, 1, 300);
    // modifiers to support scalling 
    float scallingValue = 1;
    if (image.width>image.height){
      scallingValue = (float) width / image.width;
    } else { 
      scallingValue = (float) height / image.height;
    }
    rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:1px;stroke-linejoin:round;stroke-linecap:butt;\" d=\"M "; 
    FileOutput = append(FileOutput, rowTemp);
    for (int l=0; l<lineCoords.length-1; l++){
      float distance = 0;
      if (l < lineCoords.length-1) distance = distanceBetween2Points(lineCoords[l], lineCoords[l+1]);
      if (distance<maxLength){
        rowTemp = (lineCoords[l][0] * scallingValue) + " " + (lineCoords[l][1] * scallingValue) + "\r";
        FileOutput = append(FileOutput, rowTemp);
        rowTemp = (lineCoords[l+1][0] * scallingValue) + " " + (lineCoords[l+1][1] * scallingValue) + "\r";
        FileOutput = append(FileOutput, rowTemp);
      } else {
        FileOutput = append(FileOutput, "\" />"); // End path description
        rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:1px;stroke-linejoin:round;stroke-linecap:butt;\" d=\"M "; 
        FileOutput = append(FileOutput, rowTemp);
      }
    }
    FileOutput = append(FileOutput, "\" />"); // End path description
    return FileOutput;
  }
  
  Individual clone(){
    Individual copy = new Individual(-1);
    for (int i=0; i< parameters.length; i++){
      copy.parameters[i] = parameters[i];
    }
    return copy;
  }
  
  // used by Arrays to do sort
  int compareTo(Object obj) {
    Individual other = (Individual) obj;
    if (rating > other.rating) {
      return 1;
    }
    else if (rating < other.rating) {
      return -1;
    }
    return 0;
  }
  
  String output(){
    String output = "ID:"+id+"\nrating:"+rating+"\nparents:";
    for (int i = 0; i < parents.length; i++) {
      output += parents[i];
      if (i < parents.length-1) output += ", ";
    }
    output += "\nparameters:";
    for (int i = 0; i < parameters.length; i++) {
      output += parameters[i];
      if (i < parameters.length-1) output += ", ";
    }
    output += "\n";
    return output;
  }
}