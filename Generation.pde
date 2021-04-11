// Generation builds individuals, orders them based on fitness and coordinates breeding
import java.util.Arrays;
import controlP5.*;

class Generation {
  
  Individual [] individuals = {};// an array of individuals in this generation
  float mutationProbability;
  float crossoverProbability;
  PApplet parent;
  int currentIndividualToDraw;
  Generation(PApplet p, int numIndividuals, float mp, float cp) {
    parent = p;
    mutationProbability = mp;
    crossoverProbability = cp;
   
    // Build array of individuals based on parameters
    
    for (int i=0; i< numIndividuals; i++){
      individuals = (Individual []) append(individuals, new Individual(i) );
    }
  }
  
  void evaluate() {
    // sort by rating
    Arrays.sort(individuals);
  }
    
  void evolve(Generation parent) {
    int firstQuartile = (int)individuals.length/4;
    int secondQuartile = (int)individuals.length/2;
    int thirdQuartile = (int)individuals.length-individuals.length/4;
  
    for (int i=0; i< individuals.length; i++){
      // pick the individuals to clone from the parent
      // For now use quartiles of based on the rank ordering, I don't see a need to normalize and bucket base on the values. Might later learn that a better sampling exists?
    
      float spin = random(1);
      int pick;
      //println (individuals[i]+":"+spin);
      
      if (spin <= .1){
        // 10% of time pick lower 25% of the
        pick = int(random(0,firstQuartile));
      } else if (spin <= .3) {
        // 20% if the time pick from the second quartile
        pick = int(random(firstQuartile, secondQuartile));
      } else if (spin <= .6) {
        // 30% of the time pick from the third quartile
        pick = int(random(secondQuartile, thirdQuartile));
      } else {
        // 40% of the time pick from the top quartile
        pick = int(random(thirdQuartile, individuals.length));
      }
      // ignore the 0 rated items
      if (parent.individuals[pick].rating !=0 ){
        individuals[i] = parent.individuals[pick].clone();
        individuals[i].id = i;
        // record the parent id
        individuals[i].parents = append(individuals[i].parents, pick);
      } else {
        i--;
      }
    }
    
    // loop through two at a time and based on probability, do the crossover
    for (int i=0; i< individuals.length; i=i+2){
      if (random(1) <= crossoverProbability){
        int crossoverPoint = (int) random(1, individuals[i].parameters.length);
        for (int p=0; p<crossoverPoint; p++){
          float tempParameter = individuals[i+1].parameters[p];
          
          individuals[i+1].parameters[p] = individuals[i].parameters[p];
          
          individuals[i].parameters[p] = tempParameter;
        }
        // record the second parent id
        individuals[i+1].parents = append(individuals[i+1].parents, individuals[i].parents[0]);
        individuals[i].parents = append(individuals[i].parents, individuals[i+1].parents[0]);
      } 
    }
    
    for (int i = 0; i < individuals.length; i++) {
      individuals[i].mutate(mutationProbability);
    }
  }
  
  void rate(int individual, float rating){
    individuals[individual].rate(rating);
  }
  
  public String[] getSVG(int individual, String[] FileOutput){
    return individuals[individual].getSVG(FileOutput, 0, 0);
  }
  
  public String[] getSVG(String[] FileOutput, int windowHeight){
    int gridWandH = ceil(sqrt(individuals.length));
    int width = windowHeight/gridWandH;
    int height = width;
    for (int i = 0; i < individuals.length; i++) {
      int cx = ((i%gridWandH)*width)+(width/2);
      int cy = (floor(i/gridWandH)*height)+(height/2);
      print('.');
      FileOutput = individuals[i].getSVG(FileOutput, cx, cy);
    }
    println('|');
    return FileOutput;
  }
  
  public String[] getEggbotSVG(int individual, String[] FileOutput){
    return individuals[individual].getEggbotSVG(FileOutput, 0, 0);
  }
  
  float getRating(int index){
    return individuals[index].rating;
  }
  
  void draw(PGraphics canvas, int index, int cx, int cy, int width, int height, float strokeScale){
    individuals[index].draw(canvas, cx, cy, width, height, strokeScale);

    // modifiers to support cropping to proportions of original.
    //float scallingValue = 1;
    //if (image.width>image.height){
    //  scallingValue = (float) height / image.width;
    //} else { 
    //  scallingValue = (float) height / image.height;
    //}
    //int topLeftX = height/2 - (int)(image.width*scallingValue/2);
    //int topLeftY = height/2 - (int)(image.height*scallingValue/2);
    //cache.setDrawing(currentGeneration, index, canvas.get(topLeftX, topLeftY, (int)(image.width*scallingValue), (int)(image.height*scallingValue)));
    
    // don't crop
    cache.setDrawing(currentGeneration, index, canvas.get());
  }
  
  void beginDraw(){
    currentIndex = -1;
  }
  
  boolean draw(PGraphics gcanvas, PGraphics icanvas){
    currentIndex ++;
      
    int gridWandH = ceil(sqrt(individuals.length));
    int width = gcanvas.height/gridWandH;
    int height = width;
    
    // draw all the individuals
    println("drawing "+(currentIndex+1)+" of "+individuals.length);
    this.draw(icanvas, currentIndex, icanvas.width/2, icanvas.height/2, icanvas.width, icanvas.height, 1);
    
    // place individuals on the generation grid
    int left = ((currentIndex%gridWandH)*width);
    int top = (floor(currentIndex/gridWandH)*height);
    PImage iImage = icanvas.get();
    
    gcanvas.beginDraw();
    gcanvas.image(iImage, left, top, width, height);
    gcanvas.endDraw();
    
    cache.setDrawing(currentGeneration, gcanvas.get());
    
    if (currentIndex>=individuals.length-1) {
      println("generation complete.");
      return true;
    } else {
      return false;
    }
  }
  
  void drawRatings (int left, int top, int width, int height){
    int gridWandH = ceil(sqrt(individuals.length));
    int iwidth = height/gridWandH;
    int iheight = iwidth;
    for (int i = 0; i < individuals.length; i++) {
      int ileft = ((i%gridWandH)*iwidth) + left;
      int itop = (floor(i/gridWandH)*iheight) + top;
      // draw all the background
      noStroke();
      fill(55);
      rect(ileft, itop, 18, 18);
      // draw the rating
      stroke(255);
      fill(255);
      int rating = (int)(individuals[i].rating*10);
      //int tloffset = 7;
      //if (rating == 10) tloffset = 5;
      //text(rating, (int)ileft + tloffset, (int)itop+19);
      textSize(9);
      int tloffset = 6;
      if (rating == 10) tloffset = 3;
      text(rating, (int)ileft + tloffset, (int)itop+12);
    }
  }
  
  String output(){
    String output = "";
    for (int i = 0; i < individuals.length; i++) {
      output += "\nIndividual "+ i +": ";
      output += individuals[i].output();
    }
    return output;
  }

}