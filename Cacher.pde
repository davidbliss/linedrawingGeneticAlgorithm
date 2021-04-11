class Cacher {
  PImage individualDrawing;
  PImage generationDrawing;
  String individualPath;
  String generationPath;
  
  Cacher() {
  }
  
  void setDrawing (int generationNumber, PImage drawing){
    generationPath = "temp/"+generationNumber+".png";
    generationDrawing = drawing;
    drawing.save(dataPath(generationPath));
  }
  
  void setDrawing (int generationNumber, int individualNumber, PImage drawing){
    individualPath = "temp/"+generationNumber+"_"+individualNumber+".png";
    individualDrawing = drawing;
    drawing.save(dataPath(individualPath));
  }
  
  PImage getDrawing (int generationNumber){
    String thisPath = "temp/"+generationNumber+".png";
    if (thisPath.equals(generationPath)){
      //println(millis()+" returning gen image from cache");
      return generationDrawing;
    } else {
      //println(millis()+" loading gen image from file");
      generationPath = thisPath;
      generationDrawing = loadImage(thisPath);
      return generationDrawing;
    }
  }
  
  PImage getDrawing (int generationNumber, int individualNumber){
    String thisPath = "temp/"+generationNumber+"_"+individualNumber+".png";
    if (thisPath.equals(individualPath)){
      //println(millis()+" returning individual image from cache");
      return individualDrawing;
    } else {
      //println(millis()+" loading individual image from file");
      individualPath = thisPath;
      individualDrawing = loadImage(thisPath);
      return individualDrawing;
    }
  }
}