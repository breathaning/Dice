int FRAME_RATE = 60;
float FRAME_INTERVAL = 1.0 / FRAME_RATE;
int GRAVITY = 981;
float FLOOR_HEIGHT = 30;
float DIE_CONTROL_MAX_VELOCITY = 2500;

Die die = new Die();

void setup() {
  size(750, 750, P3D);
  frameRate(60);
  die.position.x = width / 2;
  die.position.y = die.size.magnitude();
}

int old = -1;
void draw() {
  mouseInput();
  if (old == -1) {
    old = millis();
  }
  physicsStep((millis() - old) / 1000.0);
  old = millis();
  render();
}

void mouseInput() {
  if (mousePressed == true) {
    //rotation.x = radians((float)Math.random() * 360);
    //rotation.y = radians((float)Math.random() * 360);
    //rotation.z = radians((float)Math.random() * 360);
    die.rotation.x += 0.1;
    die.rotation.y += 0.1;
    die.rotation.z += 0.1;
    
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
  
  if (die.position.x < boundRadius) {
    die.position.x = boundRadius;
    die.velocity.x *= -0.5;
  }
  if (die.position.x > width - boundRadius) {
    die.position.x = width - boundRadius;
    die.velocity.x *= -0.5;
  }
  if (die.position.y < boundRadius) {
    die.position.y = boundRadius;
    die.velocity.y *= -0.5;
  }
  if (die.position.y >= height - FLOOR_HEIGHT - boundRadius) {
    if (die.velocity.y < GRAVITY * deltaTime + 5) {
      Vector3 error = die.rotation.divide(HALF_PI).round().multiply(HALF_PI).subtract(die.rotation);
      float smooth = Math.max(Math.min(3, die.velocity.magnitude() / 10), 1.5);
      die.rotation = die.rotation.add(error.divide(smooth));
    }
    if (die.velocity.y > 1) {
      die.velocity.y *= -0.3;
    }
    die.position.y = height - FLOOR_HEIGHT - boundRadius;
    die.velocity.x /= 1 + ((deltaTime / FRAME_INTERVAL) * 0.3);
  } else {
    die.rotation = die.rotation.add(die.velocity.multiply(deltaTime).multiply(0.01).absolute());
  }
}

// draw functions
void render() {
  background(100);
  lights();
  pushMatrix();
  fill(255);
  stroke(0);
  strokeWeight(2);
  translate(width / 2, height - FLOOR_HEIGHT + 4, 0);
  box(width * 2, 0, height);
  popMatrix();
  drawShadow(die.position);
  drawDice(die.position, die.rotation);
}

void drawShadow(Vector3 position) {
  float diceHeight = (height - FLOOR_HEIGHT - die.size.magnitude() / 2) - die.position.y;
  float shadowSize = die.size.magnitude() - diceHeight;
  if (shadowSize <= 0) {
    return;
  }
  pushMatrix();
  fill(50, 50, 50, shadowSize);
  strokeWeight(0);
  translate(position.x, height - FLOOR_HEIGHT - 0.01, position.z);
  rotateX(HALF_PI);
  ellipse(0, 0, shadowSize, shadowSize);
  popMatrix();
}

void drawDice(Vector3 position, Vector3 rotation) {
  pushMatrix();
  fill(255);
  stroke(0);
  strokeWeight(2);
  translateVector(position);
  rotateVector(rotation);
  boxVector(die.size);
  popMatrix();
}

// utility functions
void translateVector(Vector3 translation) {
  translate(translation.x, translation.y, translation.z);
}
void rotateVector(Vector3 rotation) {
  rotateY(rotation.y);
  rotateX(rotation.x);
  rotateZ(rotation.z);
}
void boxVector(Vector3 size) {
  box(size.x, size.y, size.z);
}

// utility classes
abstract class PVInstance {
  Vector3 position = new Vector3(0, 0, 0);
  Vector3 rotation = new Vector3(0, 0, 0);
}
abstract class PhysicsInstance extends PVInstance {
  Vector3 velocity = new Vector3(0, 0, 0);
  Vector3 size = new Vector3(50, 50, 50);
  
  PhysicsInstance() {
    super();
  }
}
class Die extends PhysicsInstance {
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
    float magnitude = magnitude();
    if (magnitude == 0) {
      return new Vector3(0, 0, 0);
    }
    return this.divide(magnitude);
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


