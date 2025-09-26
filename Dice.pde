// fine red rgb(255, 40, 67)
// beige rgb(255, 236, 207)
int FRAME_RATE = 60;
float FRAME_INTERVAL = 1.0 / FRAME_RATE;
float GRAVITY = 981;
float FLOOR_HEIGHT = 30;
float DIE_CONTROL_MAX_VELOCITY = 2500;
float DIE_STOP_SPEED_THRESHOLD = 0.1;

int INITIAL_CANVAS_WIDTH = 750;
int INITIAL_CANVAS_HEIGHT = 750;

ArrayList<Instance> instanceList = new ArrayList<Instance>();

Die die = new Die();
PVInstance focus;
PVInstance cameraInstance = new PVInstance();

void settings() {
  size(INITIAL_CANVAS_WIDTH, INITIAL_CANVAS_HEIGHT, P3D);
  smooth(2);
}

void setup() {
  frameRate(FRAME_RATE);
  
  die.position.x = width / 2;
  die.position.y = die.size.magnitude();
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
  //hint(ENABLE_DEPTH_TEST);
  updateCamera();
  lights();
  background(135, 206, 235);
  drawGround();
  drawShadow(die.position);
  drawInstances();
}

void updateCamera() {
  if (die.velocity.magnitude() <= DIE_STOP_SPEED_THRESHOLD && die.grounded) {
    Vector3 goalPosition = new Vector3(1000 * (float)Math.sin(millis() / 1000.0), 300 + 200 * (float)Math.sin(millis() / 1000.0), 1000 * (float)Math.cos(millis() / 1000.0));
    cameraInstance.position = cameraInstance.position.add(die.position.subtract(cameraInstance.position).subtract(goalPosition).divide(10));
  } else {
    cameraInstance.position = cameraInstance.position.add(die.position.subtract(cameraInstance.position).subtract(die.velocity.unit().multiply(1000).add(new Vector3(0, 250, 0))).divide(25));
  }
  camera(
    cameraInstance.position.x - (width / 2.0), cameraInstance.position.y - (height / 2.0), cameraInstance.position.z - ((height / 2.0) / tan(PI * 30.0 / 180)),
    die.position.x, die.position.y, die.position.z,
    0, 1, 0
  );
}

void drawGround() {
  pushMatrix();
  fill(37, 129, 57);
  stroke(0, 0, 0);
  strokeWeight(12);
  translateWorld(new Vector3(die.position.x, height - FLOOR_HEIGHT + 16, die.position.z));
  rotateX(radians(90));
  float scale = Math.min(Math.max(width, height) * 12, 1000);
  ellipse(0, 0, scale, scale);
  popMatrix();
}

void drawShadow(Vector3 position) {
  float diceHeight = (height - FLOOR_HEIGHT - die.size.magnitude() / 2) - die.position.y;
  float shadowSize = die.size.magnitude() - diceHeight;
  if (shadowSize <= 0) {
    return;
  }
  pushMatrix();
  fill(50, 50, 50, shadowSize);
  noStroke();
  translateWorld(new Vector3(position.x, height - FLOOR_HEIGHT - 0.01 + 4, position.z));
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
  //hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  pushMatrix();
  ellipse(width, height / 2, 50, 50);
  popMatrix();
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
    fill(255, 255, 255);
    stroke(0, 0, 0);
    strokeWeight(4);
    translateWorld(position);
    rotateWorld(rotation);
    boxWorld(die.size);
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
