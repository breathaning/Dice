// fine red rgb(255, 40, 67)
// beige rgb(255, 236, 207)
float FLOAT_PRECISION = 1.1920929E-7;

int FRAME_RATE = 60;
float FRAME_INTERVAL = 1.0 / FRAME_RATE;
float GRAVITY = 981;
float FLOOR_POSITION = 500;
float DIE_CONTROL_MAX_VELOCITY = 2500;
float DIE_STOP_SPEED_THRESHOLD = 0.1;
float DIE_LAUNCH_MAX_POWER = 1600;

int INITIAL_CANVAS_WIDTH = 750;
int INITIAL_CANVAS_HEIGHT = 750;

ArrayList<Instance> instanceList = new ArrayList<Instance>();

Die die = new Die();
CameraInstance cameraInstance = new CameraInstance();
boolean pmousePressed = mousePressed;

int pmillis = -1;
float seconds = 0;
float deltaSeconds = 0;

void settings() {
  size(INITIAL_CANVAS_WIDTH, INITIAL_CANVAS_HEIGHT, P3D);
  smooth(2);
}

void setup() {
  frameRate(FRAME_RATE);
  
  die.position.x = 0;
  die.position.y = die.size.magnitude();
  cameraInstance.center = die.position;
  cameraInstance.position = new Vector3(0, -6000, -3000);
}

void draw() {
  updateTime();
  cameraInstance.update();
  handleInput();
  physicsStep(deltaSeconds);
  
  drawWorld();
  drawUI();
}

void updateTime() {
  if (pmillis == -1) {
    pmillis = millis();
  }
  seconds = millis() / 1000.0;
  deltaSeconds = (millis() - pmillis) / 1000.0;
  pmillis = millis();
}

void handleInput() {
  boolean mouseReleased = pmousePressed && !mousePressed;

  //if (mousePressed == true) {
  //  die.rotation.x += 0.1;
  //  //die.rotation.y += 0.1;
  //  //die.rotation.z += 0.1;
  //
  //  Vector3 velocity = new Vector3(mouseX - die.position.x, mouseY - die.position.y, 0).multiply(15);
  //  if (velocity.magnitude() > DIE_CONTROL_MAX_VELOCITY) {
  //    velocity = velocity.unit().multiply(DIE_CONTROL_MAX_VELOCITY);
  //  }
  //  die.velocity = velocity;
  //}
  if (mouseReleased) {
    float dmouseX = mouseX - ((float)width / 2);
    float dmouseY = mouseY - ((float)height / 2);
    float power = Math.min(DIE_LAUNCH_MAX_POWER, 3 * (float)Math.sqrt(dmouseX * dmouseX + dmouseY * dmouseY));

    float cameraHorizontalAngle = (float)Math.atan2(cameraInstance.center.z - cameraInstance.position.z, cameraInstance.center.x - cameraInstance.position.x);
    float mouseAngle = (float)Math.atan2(dmouseY, dmouseX) - HALF_PI;
    float horizontalAngle = cameraHorizontalAngle + mouseAngle;
    float verticalAngle = radians(45) * -(power / DIE_LAUNCH_MAX_POWER);
    
    die.velocity = new Vector3((float)Math.cos(horizontalAngle), (float)Math.sin(verticalAngle), (float)Math.sin(horizontalAngle)).multiply(power);
  }

  pmousePressed = mousePressed;
}

void physicsStep(float deltaTime) {
  die.rotation = die.rotation.normalize(TWO_PI);
  die.velocity.y += GRAVITY * deltaTime;
  die.position = die.position.add(die.velocity.multiply(deltaTime));

  float boundRadius = die.size.average() / 2;

  die.grounded = die.velocity.y < GRAVITY * deltaTime + 5;
  if (die.position.y >= FLOOR_POSITION - boundRadius) {
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
    die.position.y = FLOOR_POSITION - boundRadius;
    
    Vector3 horizontalVelocity = new Vector3(die.velocity.x, 0, die.velocity.z);
    float friction = 1 / (1 + ((deltaTime / FRAME_INTERVAL) * 0.3));
    horizontalVelocity = horizontalVelocity.unit().multiply(horizontalVelocity.magnitude() *friction);
    die.velocity.x = horizontalVelocity.x;
    die.velocity.z = horizontalVelocity.z;
  } else {
    die.rotation = die.rotation.add(die.velocity.multiply(deltaTime).multiply(0.01).absolute());
  }
}

// draw functions
void drawWorld() {
  hint(ENABLE_DEPTH_TEST);
  float eyeX = cameraInstance.position.x;
  float eyeZ = cameraInstance.position.z;
  if (eyeX == cameraInstance.center.x) {
    eyeX += FLOAT_PRECISION;
  }
  if (eyeZ == cameraInstance.center.z) {
    eyeZ += FLOAT_PRECISION;
  }
  camera(
    eyeX, cameraInstance.position.y, eyeZ,
    cameraInstance.center.x, cameraInstance.center.y, cameraInstance.center.z,
    0, 1, 0
  );
  lights();
  background(135, 206, 235);
  pushMatrix();
  drawGround();
  drawShadow(die.position);
  drawInstances();
  popMatrix();
}


void drawGround() {
  pushMatrix();
  fill(37, 129, 57);
  stroke(0, 0, 0);
  strokeWeight(12);
  translateWorld(new Vector3(cameraInstance.position.x, FLOOR_POSITION + 16, cameraInstance.position.z));
  rotateX(radians(90));
  float scale = Math.min(Math.max(width, height) * 5, 8000);
  ellipse(0, 0, scale, scale);
  popMatrix();
}

void drawShadow(Vector3 position) {
  float diceHeight = (FLOOR_POSITION - die.size.magnitude() / 2) - die.position.y;
  float shadowSize = die.size.magnitude() - diceHeight;
  if (shadowSize <= 0) {
    return;
  }
  pushMatrix();
  fill(50, 50, 50, shadowSize);
  noStroke();
  translateWorld(new Vector3(position.x, FLOOR_POSITION - 0.01 + 4, position.z));
  rotateX(HALF_PI);
  ellipse(0, 0, shadowSize, shadowSize);
  popMatrix();
}

void drawInstances() {
  for (int i = 0; i < instanceList.size(); i++) {
    pushMatrix();
    instanceList.get(i).draw();
    popMatrix();
  }
}

void drawUI() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  pushMatrix();
  drawLaunchCharge();
  popMatrix();
}

void drawLaunchCharge() {
  if (mousePressed == false) {
    return;
  }
  int dmouseX = mouseX - (width / 2);
  int dmouseY = mouseY - (height / 2);
  fill(255, 100, 0, 150);
  int amt = 10;
  float exp = 0.8;
  float sizeMultiplier = 1.5 - ((float)Math.sqrt(dmouseX * dmouseX + dmouseY * dmouseY) / (float)Math.sqrt(width * width / 4 + height * height / 4));
  for (int i = 1; i <= amt; i++) {
    float size = sizeMultiplier * (i * 2 + 5);
    ellipse(width / 2 + dmouseX * (float)Math.pow((float)i / amt, exp), height / 2 + dmouseY * (float)Math.pow((float)i / amt, exp), size, size);
  }
}

// utility functions
void translateWorld(Vector3 translation) {
  translate(translation.x, translation.y, translation.z);
}

void rotateWorld(Vector3 rotation) {
  rotateX(rotation.x);
  rotateY(rotation.y);
  rotateZ(rotation.z);
}

void boxWorld(Vector3 size) {
  box(size.x, size.y, size.z);
}

Vector3 getLookVector(Vector3 vectorOne, Vector3 vectorTwo) {
  Vector3 deltaVector = vectorTwo.subtract(vectorOne);
  if (deltaVector.magnitude() == 0) {
    return new Vector3(0, 0, -1);
  }
  return deltaVector.unit();
}

// utility classes
class Instance {
  
  Instance() {
    instanceList.add(this);
  }
  
  void draw() {}

  void destroy() {
    instanceList.remove(this);
  }
}

class PVInstance extends Instance {
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
  
  void draw() {
    if (position.subtract(cameraInstance.position).magnitude() < size.magnitude()) {
      return;
    }
    fill(255, 255, 255);
    stroke(0, 0, 0);
    strokeWeight(4);
    translateWorld(position);
    rotateWorld(rotation);
    boxWorld(this.size);

    int lift = 1;
    float dotSize = size.average() / 5;
    fill(0, 0, 0);
    noStroke();
    // 1
    pushMatrix();
    translate(0, 0, size.z / 2 + lift);
    ellipse(0, 0, dotSize, dotSize);
    popMatrix();
    // 2
    pushMatrix();
    translate(size.x / 2 + lift, 0, 0);
    rotateY(-HALF_PI);
    ellipse(-size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(size.x / 4, -size.y / 4, dotSize, dotSize);
    popMatrix();
    // 3
    pushMatrix();
    translate(0, -size.y / 2 - lift, 0);
    rotateX(-HALF_PI);
    rotate(HALF_PI);
    ellipse(-size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(0, 0, dotSize, dotSize);
    ellipse(size.x / 4, -size.y / 4, dotSize, dotSize);
    popMatrix();
    // 4
    pushMatrix();
    translate(0, size.y / 2 + lift, 0);
    rotateX(HALF_PI);
    ellipse(size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(size.x / 4, -size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, -size.y / 4, dotSize, dotSize);
    popMatrix();
    // 5
    pushMatrix();
    translate(-size.z / 2 - lift, 0, 0);
    rotateY(HALF_PI);
    ellipse(0, 0, dotSize, dotSize);
    ellipse(size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(size.x / 4, -size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, -size.y / 4, dotSize, dotSize);
    popMatrix();
    // 6
    pushMatrix();
    translate(0, 0, -size.z / 2 - lift);
    rotateX(PI);
    ellipse(size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(size.x / 4, 0, dotSize, dotSize);
    ellipse(size.x / 4, -size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, size.y / 4, dotSize, dotSize);
    ellipse(-size.x / 4, 0, dotSize, dotSize);
    ellipse(-size.x / 4, -size.y / 4, dotSize, dotSize);
    popMatrix();
  }
}

class CameraInstance extends PVInstance {
  Vector3 center;
  Vector3 lookVector;

  CameraInstance() {
    center = new Vector3(0, 0, 0);
    lookVector = new Vector3(0, 0, -1);
  }

  void update() {
    Vector3 pcenter = center.copy();
    center = center.add(die.position.subtract(center).divide(10));
    Vector3 centerVelocity;
    if (deltaSeconds == 0) {
      centerVelocity = new Vector3(0, 0, 0);
    } else {
      centerVelocity = center.subtract(pcenter).divide(deltaSeconds);
    }
    if (die.velocity.magnitude() <= DIE_STOP_SPEED_THRESHOLD && die.grounded) {
      Vector3 goalPosition = new Vector3(1000 * (float)Math.sin(seconds), 300 + 200 * (float)Math.sin(seconds), 1000 * (float)Math.cos(seconds));
      position = position.add(center.subtract(position).subtract(goalPosition).divide(10));
    } else {
      position = position.add(center.subtract(position).subtract(centerVelocity.unit().multiply(1000).add(new Vector3(0, 250, 0))).divide(25));
    }
    if (position.y > FLOOR_POSITION - FLOAT_PRECISION) {
      position.y = FLOOR_POSITION - FLOAT_PRECISION;
    }
    lookVector = center.subtract(position).unit();
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