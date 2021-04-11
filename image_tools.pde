void loadFromFile(){
  cp5.getGroup("all").setVisible(false);
  selectInput("Select a file to process:", "parseFilePath");
}

void parseFilePath(File selection){
  if (selection == null) {
    println("dialog closed or canceled.");
  } else {
    println("path selected " + selection.getAbsolutePath());
    loadImageFromDisk(selection.getAbsolutePath());
  }
}

void loadImageFromDisk(String path){
  println("Loading image: "+path);
  PImage img = loadImage(path);
  
  if (img.width>img.height){
    // resize to width = 2000
    img.resize(2000, 2000*img.height/img.width);
  } else {
    // resize to height = 2000
    img.resize(2000*img.width/img.height, 2000);
  }
  // resize proportionately to 
  println("image loaded");
  initGA(img);
}