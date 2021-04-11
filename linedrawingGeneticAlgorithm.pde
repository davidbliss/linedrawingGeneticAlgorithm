import controlP5.*;
ControlP5 cp5;
Cacher cache = new Cacher();

PGraphics individualOffscreenCanvas;
PGraphics generationOffscreenCanvas;

Generation [] generations; // an array of generations

Textarea individualIndexText;
Textarea generationIndexText;

int numIndividuals = 36; // must be even
float mutationPropability = .1; // likely target should be 1% of the time
float crossoverProbability = .75; // likely target should be 75% of the time
float defaultRating = 0; // start as fairly rated so easier to only rate up ones you like and rate down ones you don't

int canvasSize = 3200;
int currentIndex = 0;
int currentGeneration = 0;

String saveIndividualFilePath = "none";
String saveGenerationFilePath = "none";

PImage image;

Individual [] lineage = {}; // an array of individuals 

final int INITIALIZING = 0;
final int DRAWING_GENERATION = 1;
final int DRAW_READY = 2;
final int OVERLAID = 3;
static int appState;

void initGA(PImage img){
  // called when image loads
  image = img;
  currentIndex = 0;
  currentGeneration = 0;
  generations = new Generation [1];
  // create initial generation
  generations[0] = new Generation(this, numIndividuals, mutationPropability, crossoverProbability);  

  drawGeneration();
}

void setup() {
  //size(1000, 800, P3D);
  size(1800, 800, P3D);
  
  individualOffscreenCanvas = createGraphics(canvasSize, canvasSize, P3D);
  generationOffscreenCanvas = createGraphics(canvasSize, canvasSize, P3D);
  
  appState = INITIALIZING;
  
  cp5 = new ControlP5(this);
  
  cp5.addTextarea("0123456789")
    .setPosition(0,10)
    .setColor(0)
    .setSize(200, 20)
    ;
    
  Group all = cp5.addGroup("all")
    .setPosition(0,0)
    ;
  
  Group settingsGeneration = cp5.addGroup("settingsGeneration")
    .setLabel("Generation")
    .setPosition(height+20+90,20)
    .setWidth(70)
    .setBackgroundHeight(200)
    .setGroup(all)
    ;
  
  generationIndexText = cp5.addTextarea("generationIndexText")
    .setPosition(0,10)
    .setColor(0)
    .setSize(200, 20)
    .setGroup(settingsGeneration)
    ;
  
  cp5.addButton("previousGeneration")
    .setLabel("<")
    .setWidth(30)
    .setPosition(0,30)
    .setGroup(settingsGeneration)
    ;
  
  cp5.addButton("nextGeneration")
    .setLabel(">")
    .setWidth(30)
    .setPosition(40,30)
    .setGroup(settingsGeneration)
    ;
    
  cp5.addButton("evolve")
    .setPosition(0,60)
    .setGroup(settingsGeneration)
    ;

  cp5.addButton("refresh")
    .setPosition(0,120)
    .setGroup(settingsGeneration)
    ;
    
  cp5.addButton("generationOutput")
    .setLabel("output")
    .setPosition(0,170)
    .setGroup(settingsGeneration)
    ;
    
  cp5.addButton("generationPNG")
    .setLabel("PNG")
    .setPosition(0,200)
    .setGroup(settingsGeneration)
    ;

  Group settingsIndividual = cp5.addGroup("settingsIndividual")
    .setLabel("Individual")
    .setPosition(height+20,20)
    .setWidth(70)
    .setBackgroundHeight(200)
    .setGroup(all)
    ;
    
  individualIndexText = cp5.addTextarea("individualIndexText")
    .setPosition(0,10)
    .setColor(0)
    .setSize(200, 20)
    .setGroup(settingsIndividual)
    ;
  
  cp5.addButton("previousIndividual")
    .setLabel("<")
    .setWidth(30)
    .setPosition(0,30)
    .setGroup(settingsIndividual)
    ;
  
  cp5.addButton("nextIndividual")
    .setLabel(">")
    .setWidth(30)
    .setPosition(40,30)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addTextarea("rating label")
    .setText("RATING")
    .setColor(0)
    .setSize(70, 20)
    .setPosition(0,75)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addSlider("rating")
    .setTriggerEvent(Slider.RELEASE)
    .setBroadcast(false)
    .setColorTickMark(0)
    .setPosition(0,90)
    .setWidth(70)
    .setRange(0,1)
    .setNumberOfTickMarks(6)
    .setBroadcast(true)
    .setValue(defaultRating)
    .setGroup(settingsIndividual)
    .setLabelVisible(false)
    ;
       
  cp5.addTextarea("resolution label")
    .setText("MAX LINES")
    .setColor(0)
    .setSize(80, 20)
    .setPosition(0,115)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addSlider("resolution")
    .setTriggerEvent(Slider.RELEASE)
    .setBroadcast(false)
    .setPosition(0,130)
    .setColorTickMark(0)
    .setWidth(70)
    .setRange(0,1)
    .setNumberOfTickMarks(11)
    .setBroadcast(true)
    .setValue(.5)
    .setGroup(settingsIndividual)
    .setLabelVisible(false)
    ;
    
  cp5.addButton("individualOutput")
    .setLabel("output")
    .setPosition(0,170)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addButton("individualPNG")
    .setLabel("PNG")
    .setPosition(0,200)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addButton("individualSVG")
    .setLabel("SVG")
    .setPosition(0,230)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addButton("individualEggbotSVG")
    .setLabel("eggbot SVG")
    .setPosition(0,260)
    .setGroup(settingsIndividual)
    ;
    
  cp5.addButton("loadFromFile")
   .setLabel("load image")
   .setPosition(height+20,height-40)
   .setGroup(all)
   ;
 
  // hardcode path to make dev quicker
  //loadImageFromDisk("/Users/davidbliss/Desktop/tree.jpg");
}

void draw() {
  
  if (appState == DRAWING_GENERATION){
    boolean drawingDone = generations[currentGeneration].draw(generationOffscreenCanvas, individualOffscreenCanvas);
    if (drawingDone == true) {
      appState = DRAW_READY;
      cp5.getGroup("all").setVisible(true);
      manualDraw();
    } else {
      manualDraw();
    }
  }
  
  // check to see if you should save an Image
  if (saveIndividualFilePath!="none"){
    PImage e = get(0, 0, 0, 0);
    e = cache.getDrawing (currentGeneration, currentIndex);
    e.save(saveIndividualFilePath);
    saveIndividualFilePath="none";
    println("individual image saved");
    println("--------------------------");
  }
  
  if (saveGenerationFilePath!="none"){
    PImage e = get(0, 0, 0, 0);
    e = cache.getDrawing (currentGeneration);
    e.save(saveGenerationFilePath);
    saveGenerationFilePath="none";
    println("generation image saved");
    println("--------------------------");
  }
}

void manualDraw() {
  // called after an interaction with UI
  //println("manualDraw, appstate: "+appState);
  background(200);
 
  if (appState==DRAWING_GENERATION || appState==DRAW_READY){
    // hide evolve if generation is not the latest
    if (currentGeneration<generations.length-1) cp5.getController("evolve").setPosition(0,-2000);
    else cp5.getController("evolve").setPosition(0,60);
    
    PImage individualImage = cache.getDrawing (currentGeneration, currentIndex);
    
    // modifiers to support scalling 
    float scallingValue = 1;
    if (individualImage.width>individualImage.height){
      scallingValue = (float) height / individualImage.width;
    } else { 
      scallingValue = (float) height / individualImage.height;
    }
    int topLeftX = height/2 - (int)(individualImage.width*scallingValue/2);
    int topLeftY = height/2 - (int)(individualImage.height*scallingValue/2);
    
    image(individualImage,topLeftX,topLeftY,individualImage.width*scallingValue,individualImage.height*scallingValue);
    
    PImage generationImage = cache.getDrawing (currentGeneration);
    image(generationImage,width-height,0,height,height);
    
    generationIndexText.setText((currentGeneration+1) + " of " + generations.length);
    cp5.getController("rating").setValue(generations[currentGeneration].getRating(currentIndex));
    individualIndexText.setText((currentIndex+1) + " of " + numIndividuals);
    
    generations[currentGeneration].drawRatings (width-height, 0, height, height);
  }
}

void refresh(){
  drawGeneration();
}

void evolve(){
  // first check that something has been rated.
  boolean proceed = false;
  for (int i=0; i< numIndividuals; i++){
    if(generations[currentGeneration].individuals[i].rating != 0) {
      println("we will proceed with evolution");
      println(""+generations[currentGeneration].individuals[i].rating);
      proceed = true;
    }
  }
  if (proceed==true){
    // create a new generation 
    generations = (Generation[]) append (generations, new Generation(this, numIndividuals, mutationPropability, crossoverProbability));
    generations[currentGeneration].evaluate();
    // evolve latest generation based on previous generation
    generations[generations.length-1].evolve(generations[currentGeneration]);
    currentGeneration = generations.length-1;
    drawGeneration();
  } else {
    println("you need to rate something before proceeding");
  }
}

void drawGeneration(){
  cp5.getGroup("all").setVisible(false);
  generationOffscreenCanvas = createGraphics(canvasSize, canvasSize, P3D);
  generations[currentGeneration].beginDraw();
  appState = DRAWING_GENERATION;
}

void controlEvent(ControlEvent theEvent){
  // Handle events from UI
  String name = theEvent.getController().getName();
  println("controlEvent "+ name);
  if (name.indexOf("rating")>-1) {
    generations[currentGeneration].rate(currentIndex,theEvent.getController().getValue());
  } 
  
  if (name!="refresh" && name!="evolve" &&name!="generationPNG" && name!="individualPNG" && name!="individualSVG" && name!="individualEggbotSVG" && name!="individualOutput" && name!="generationOutput") manualDraw();
}

void nextIndividual(){
  if (currentIndex<numIndividuals-1) currentIndex++;
  else currentIndex = 0;
}

void previousIndividual(){
  if (currentIndex>0) currentIndex--;
  else currentIndex = numIndividuals-1;
}

void nextGeneration(){
  if (currentGeneration<generations.length-1) currentGeneration++;
  else currentGeneration = 0;
}

void previousGeneration(){
  if (currentGeneration>0) currentGeneration--;
  else currentGeneration = generations.length-1;
}

void generationOutput(){
  //TODO: create a more export friendly format (Json or CSV)
  println("output:");
  String output="";
  for (int i = 0; i < generations.length; i++) {
    output += "\n ==================== \n";
    output += "Generation:"+ i +"\n";
    output += generations[i].output();
  }
  println(output);
}

void individualOutput(){
  //TODO: create a more export friendly format (Json or CSV)
  println("output:");
  String output="";
  for (int i = 0; i < generations.length; i++) {
    output += "\n ==================== \n";
    output += generations[currentIndex].output();
  }
  println(output);
}

void mouseClicked() {
  if (appState == DRAW_READY){
    int adjustedMouseX=mouseX-(width-height);
    if (adjustedMouseX < height && adjustedMouseX > 0 && mouseY < height && mouseY >0){
      int gridWandH = ceil(sqrt(numIndividuals));
      int gridWidth = height/gridWandH;
      int gridHeight = gridWidth;
      for (int i = 0; i < numIndividuals; i++) {
        int x = ((i%gridWandH)*gridWidth);
        int y = (floor(i/gridWandH)*gridHeight);
        if (adjustedMouseX < x+gridWidth && adjustedMouseX > x && mouseY < y+gridHeight && mouseY >y){
          currentIndex = i;
        }
      }
      manualDraw();
    }
  }
}

void mousePressed() {
  if (appState == DRAW_READY){
    if (mouseX < height && mouseX > 0 && mouseY < height && mouseY >0){
      cp5.getGroup("all").setVisible(false);
      float clickedX = mouseX/(float)height;
      float clickedY = mouseY/(float)height;
      fill(0,70);
      rect(0,0,width, height);
      PImage individualImage = cache.getDrawing (currentGeneration, currentIndex);
      int left = width/2 - (int)(individualImage.width*clickedX);
      int top = height/2 - (int)(individualImage.height*clickedY);
      image(individualImage,left,top);
      appState = OVERLAID;
    }
  }
}

void mouseReleased() {
  if (appState == OVERLAID){
    cp5.getGroup("all").setVisible(true);
    appState = DRAW_READY;
    manualDraw();
  }
}

/////////
// EXPORTING PNG AND SVG
/////////

void individualPNG(){
  // if accelerating displayCanvas with P2D or P3D, calling selectOutput crashes. 
  // This is because openGl can only be called inside the main animation thread (draw or something called from within draw)
  // Need to save a file name as variable and then call save based on a flag being present
  selectOutput("Output name:", "IndividualPNGFileSelected");
}

void generationPNG(){
  // if accelerating displayCanvas with P2D or P3D, calling selectOutput crashes. 
  // This is because openGl can only be called inside the main animation thread (draw or something called from within draw)
  // Need to save a file name as variable and then call save based on a flag being present
  selectOutput("Output name:", "GenerationPNGFileSelected");
}

void individualSVG(){
  // if accelerating displayCanvas with P2D or P3D, calling selectOutput crashes. 
  // This is because openGl can only be called inside the main animation thread (draw or something called from within draw)
  // Need to save a file name as variable and then call save based on a flag being present
  selectOutput("Output name:", "IndividualSVGFileSelected");
}

void individualEggbotSVG(){
  // if accelerating displayCanvas with P2D or P3D, calling selectOutput crashes. 
  // This is because openGl can only be called inside the main animation thread (draw or something called from within draw)
  // Need to save a file name as variable and then call save based on a flag being present
  selectOutput("Output name:", "IndividualEggbotSVGFileSelected");
}

void IndividualPNGFileSelected(File selection){
  // Individual PNG
  String saveFilePath = selection.getAbsolutePath();
  String[] p = splitTokens(saveFilePath, ".");
  saveIndividualFilePath = p[0] + "_individual.png";
  println("Saving Individual PNG file: "+saveFilePath);
}

void GenerationPNGFileSelected(File selection){
  // Generation PNG
  String saveFilePath = selection.getAbsolutePath();
  String[] p = splitTokens(saveFilePath, ".");
  saveGenerationFilePath = p[0] + "_generation.png";
  println("Saving generation PNG files: "+saveFilePath);
}

void IndividualSVGFileSelected(File selection){
  // SVG
  String svgFilePath = selection.getAbsolutePath();
  String[] p = splitTokens(svgFilePath, ".");
  String svgPath = p[0] + ".svg";
  println("Saving Individual SVG File: "+svgPath);
  String[] FileOutput = loadStrings("svg_header.txt");
  
  FileOutput = generations[currentGeneration].getSVG(currentIndex, FileOutput);
  
  // SVG footer:
  FileOutput = append(FileOutput, "</g></g></svg>");
  saveStrings(svgPath, FileOutput);
  println("Individual SVG saving complete");
  println("--------------------------");
}

void GenerationSVGFileSelected(File selection){
  // SVG
  String svgFilePath = selection.getAbsolutePath();
  String[] p = splitTokens(svgFilePath, ".");
  String svgPath = p[0] + ".svg";
  println("Saving Generation SVG File: "+svgPath);
  String[] FileOutput = loadStrings("svg_header.txt"); 
  
  // TODO: add a button for the brave to call this (and test it)
  FileOutput = generations[currentGeneration].getSVG(FileOutput, height);
  
  // SVG footer:
  FileOutput = append(FileOutput, "</g></g></svg>");
  saveStrings(svgPath, FileOutput);
  println("Generation SVG saving complete");
  println("--------------------------");
}

void IndividualEggbotSVGFileSelected(File selection){
  // Eggbot SVG is SVG with fewer pen drops and no line variation
  String svgFilePath = selection.getAbsolutePath();
  String[] p = splitTokens(svgFilePath, ".");
  String svgPath = p[0] + ".svg";
    
  println("Saving Eggbot SVG File: "+svgPath);

  String[] FileOutput = loadStrings("svg_header.txt"); 

  FileOutput = generations[currentGeneration].getEggbotSVG(currentIndex, FileOutput);
  
  // SVG footer:
  FileOutput = append(FileOutput, "</g></g></svg>");
  saveStrings(svgPath, FileOutput);
  println("Eggbot SVG saving complete");
  println("--------------------------");
}
