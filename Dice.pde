int FRAME_RATE = 60;
float FRAME_INTERVAL = 1.0 / FRAME_RATE;
float GRAVITY = 981;
float FLOOR_HEIGHT = 30;
float DIE_CONTROL_MAX_VELOCITY = 2500;
float DIE_STOP_SPEED_THRESHOLD = 0.1;

int INITIAL_CANVAS_WIDTH = 750;
int INITIAL_CANVAS_HEIGHT = 750;

Die die = new Die();
PVInstance focus;
PVInstance cameraInstance = new PVInstance();

PGraphics worldCanvas;
PGraphics worldCanvasMain;
PGraphics worldCanvasFullscreen;

void settings() {
  size(INITIAL_CANVAS_WIDTH, INITIAL_CANVAS_HEIGHT, P2D);
}

void setup() {
  worldCanvasMain = createGraphics(width, height, P3D);
  try {
    worldCanvasFullscreen = createGraphics(displayWidth, displayHeight, P3D);
  } catch (Exception e) {
    // don't have to instantiate, just in case 
    worldCanvasFullscreen = createGraphics(width, height, P3D);
  }
  renderHints(worldCanvasMain);
  renderHints(worldCanvasFullscreen);
  
  frameRate(60);
  die.position.x = width / 2;
  die.position.y = die.size.magnitude();
}

void renderHints(PGraphics canvas) {
  canvas.hint(ENABLE_OPENGL_4X_SMOOTH);
  canvas.hint(ENABLE_STROKE_PERSPECTIVE);
}

int old = -1;
void draw() {
  handleInput();
  if (old == -1) {
    old = millis();
  }
  physicsStep((millis() - old) / 1000.0);
  old = millis();
  drawWorld();
  drawUI();
}

void handleInput() {
  if (mousePressed == true) {
    die.rotation.x += 0.1;
    //die.rotation.y += 0.1;
    //die.rotation.z += 0.1;
    
    Vector3 velocity = new Vector3(mouseX - die.position.x, mouseY - die.position.y, 0).multiply(15);
    if (velocity.magnitude() > DIE_CONTROL_MAX_VELOCITY) {
      velocity = velocity.unit().multiply(DIE_CONTROL_MAX_VELOCITY);
    }
    die.velocity = velocity;
  }
}

void physicsStep(float deltaTime) {
  die.rotation = die.rotation.normalize(TWO_PI);
  die.velocity.y += GRAVITY * deltaTime;
  die.position = die.position.add(die.velocity.multiply(deltaTime));
  
  float boundRadius = die.size.average() / 2;
  
  die.grounded = die.velocity.y < GRAVITY * deltaTime + 5;
  if (die.position.y >= height - FLOOR_HEIGHT - boundRadius) {
    if (die.grounded) {
      Vector3 error = die.rotation.divide(HALF_PI).round().multiply(HALF_PI).subtract(die.rotation);
      float smooth = Math.max(Math.min(3, die.velocity.magnitude() / 10), 1.5);
      die.rotation = die.rotation.add(error.divide(smooth));
      if (die.velocity.magnitude() < DIE_STOP_SPEED_THRESHOLD) {
        die.velocity = new Vector3(0, 0, 0);
      }
    }
    if (die.velocity.y > GRAVITY * deltaTime + 1) {
      die.velocity.y *= -0.3;
    } else {
      die.velocity.y = 0;
    }
    die.position.y = height - FLOOR_HEIGHT - boundRadius;
    die.velocity.x /= 1 + ((deltaTime / FRAME_INTERVAL) * 0.3);
  } else {
    die.rotation = die.rotation.add(die.velocity.multiply(deltaTime).multiply(0.01).absolute());
  }
}

// draw functions
void drawWorld() {
  if (width == INITIAL_CANVAS_WIDTH && height == INITIAL_CANVAS_HEIGHT) {
    worldCanvas = worldCanvasMain;
  } else {
    worldCanvas = worldCanvasFullscreen;
  }
  worldCanvas.beginDraw();
  updateCamera();
  worldCanvas.noLights();
  worldCanvas.lights();
  worldCanvas.background(135, 206, 235);
  drawGround();
  drawShadow(die.position);
  drawDice(die.position, die.rotation);
  worldCanvas.endDraw();
  image(worldCanvas, 0, 0);
}

void updateCamera() {
  if (die.velocity.magnitude() <= DIE_STOP_SPEED_THRESHOLD && die.grounded) {
    Vector3 goalPosition = new Vector3(1000 * (float)Math.sin(millis() / 1000.0), 300 + 200 * (float)Math.sin(millis() / 1000.0), 1000 * (float)Math.cos(millis() / 1000.0));
    cameraInstance.position = cameraInstance.position.add(die.position.subtract(getCameraWorldPosition(cameraInstance.position)).subtract(goalPosition).divide(10));
  } else {
    cameraInstance.position = cameraInstance.position.add(die.position.subtract(getCameraWorldPosition(cameraInstance.position)).subtract(die.velocity.unit().multiply(1000).add(new Vector3(0, 250, 0))).divide(25));
  }
  Vector3 cameraWorldPosition = getCameraWorldPosition(cameraInstance.position);
  worldCanvas.camera(
    cameraWorldPosition.x, cameraWorldPosition.y, cameraWorldPosition.z, 
    die.position.x, die.position.y, die.position.z, 
    0, 1, 0
  );
}

void drawGround() {
  worldCanvas.pushMatrix();
  worldCanvas.fill(37, 129, 57);
  worldCanvas.stroke(0, 0, 0);
  worldCanvas.strokeWeight(8);
  translateWorld(new Vector3(cameraInstance.position.x, height - FLOOR_HEIGHT + 16, cameraInstance.position.z));
  worldCanvas.rotateX(radians(90));
  float scale = Math.min(Math.max(width, height) * 12, 11000);
  worldCanvas.ellipse(0, 0, scale, scale);
  worldCanvas.popMatrix();
}

void drawShadow(Vector3 position) {
  float diceHeight = (height - FLOOR_HEIGHT - die.size.magnitude() / 2) - die.position.y;
  float shadowSize = die.size.magnitude() - diceHeight;
  if (shadowSize <= 0) {
    return;
  }
  worldCanvas.pushMatrix();
  worldCanvas.fill(50, 50, 50, shadowSize);
  worldCanvas.noStroke();
  translateWorld(new Vector3(position.x, height - FLOOR_HEIGHT - 0.01 + 4, position.z));
  worldCanvas.rotateX(HALF_PI);
  worldCanvas.ellipse(0, 0, shadowSize, shadowSize);
  worldCanvas.popMatrix();
}

void drawDice(Vector3 position, Vector3 rotation) {
  worldCanvas.pushMatrix();
  worldCanvas.fill(255, 255, 255);
  worldCanvas.stroke(0, 0, 0);
  worldCanvas.strokeWeight(4);
  translateWorld(position);
  rotateWorld(rotation);
  boxWorld(die.size);
  worldCanvas.popMatrix();
}

void drawUI() {
  pushMatrix();
  //ellipse(width / 2, height / 2, 50, 50);
  popMatrix();
}

// utility functions
void translateWorld(Vector3 translation) {
  worldCanvas.translate(translation.x, translation.y, translation.z);
}

void rotateWorld(Vector3 rotation) {
  worldCanvas.rotateX(rotation.x);
  worldCanvas.rotateY(rotation.y);
  worldCanvas.rotateZ(rotation.z);
}

void boxWorld(Vector3 size) {
  worldCanvas.box(size.x, size.y, size.z);
}

Vector3 getLookVector(Vector3 vectorOne, Vector3 vectorTwo) {
  Vector3 deltaVector = vectorTwo.subtract(vectorOne);
  if (deltaVector.magnitude() == 0) {
    return new Vector3(0, 0, -1);
  }
  return deltaVector.unit();
}

Vector3 getCameraWorldPosition(Vector3 position) {
  return new Vector3(
    position.x + width / 2.0, 
    position.y + height / 2.0, 
    position.z + (height / 2.0) / tan(PI * 30.0 / 180)
  );
}


// utility classes
class PVInstance {
  Vector3 position = new Vector3(0, 0, 0);
  Vector3 rotation = new Vector3(0, 0, 0);
}
class PhysicsInstance extends PVInstance {
  Vector3 velocity = new Vector3(0, 0, 0);
  Vector3 size = new Vector3(50, 50, 50);
  
  PhysicsInstance() {
    super();
  }
}
class Die extends PhysicsInstance {
  boolean grounded = false;
  Die() {
    super();
  }
}
class Vector3 {
  float x;
  float y;
  float z;
  
  Vector3(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  
  Vector3 add(Vector3 otherVector) {
    return new Vector3(x + otherVector.x, y + otherVector.y, z + otherVector.z);
  }
  
  Vector3 subtract(Vector3 otherVector) {
    return add(otherVector.inverse());
  }
  
  Vector3 multiply(float scalar) {
    return new Vector3(x * scalar, y * scalar, z * scalar);
  }
  
  Vector3 divide(float scalar) {
    return new Vector3(x / scalar, y / scalar, z / scalar);
  }
  
  Vector3 normalize(float max) {
    return new Vector3(x % max, y % max, z % max);
  }
  
  Vector3 inverse() {
   return new Vector3(-x, -y, -z); 
  }
  
  Vector3 absolute() {
    return new Vector3(Math.abs(x), Math.abs(y), Math.abs(z));
  }
  
  Vector3 unit() {
    float magnitudeValue = magnitude();
    if (magnitudeValue == 0) {
      return new Vector3(0, 0, 0);
    }
    return this.divide(magnitudeValue);
  }
  
  Vector3 round() {
    return new Vector3(Math.round(x), Math.round(y), Math.round(z));
  }
  
  Vector3 copy() {
    return new Vector3(x, y, z);
  }
  
  float average() { 
    return (Math.abs(x) + Math.abs(y) + Math.abs(z)) / 3;
  }
  
  float magnitude() {
    return (float)Math.sqrt((x * x) + (y * y) + (z * z));
  }
}
