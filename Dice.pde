// fine red rgb(255, 40, 67)
// beige rgb(255, 236, 207)
float FLOAT_PRECISION = 1.1920929E-7;

int FRAME_RATE = 1000; // -1 doesn't work on processing
int SIMULATION_RATE = 60;
float SIMULATION_INTERVAL = 1.0 / SIMULATION_RATE;
float GRAVITY = 981;
float FLOOR_POSITION = 500;
float DIE_CONTROL_MAX_VELOCITY = 2500;
float DIE_STOP_SPEED_THRESHOLD = 0.1;
float DIE_LAUNCH_MAX_POWER = 1600;
float DIE_LAUNCH_MIN_POWER = 800;
float DIE_LAUNCH_MOUSE_DEADZONE = 150;
float DIE_LAUNCH_MOUSE_STARTZONE = 100;

ArrayList<Instance> instanceList = new ArrayList<Instance>();

boolean gameOn = false;

// game objects
DiePhysicsInstance die = new DiePhysicsInstance();
CameraInstance cameraInstance = new CameraInstance();
float dieLaunchPower = 0;
boolean dieLaunched = false;
int correspondingDieButton = -1;

// home screen
ArrayList<UIInstance> homeInstanceList = new ArrayList<UIInstance>();
ArrayList<Die> homeDieList = new ArrayList<Die>();
TextInstance homeDiceTotalText = new TextInstance("Total: 0", 0, 300, 32, color(0, 0, 0));  
{
  // text
  homeInstanceList.add(new TextInstance("Click the dice to roll them!", 0, -300, 32, color(0, 0, 0)));
  homeInstanceList.add(homeDiceTotalText);
  // top row
  homeDieList.add(new Die(0, -225, -150, 100, color(255, 0, 0), color(128, 0, 0)));
  homeDieList.add(new Die(0, -75, -150, 100, color(255, 70, 0), color(128, 35, 0)));
  homeDieList.add(new Die(0, 75, -150, 100, color(255, 255, 0), color(128, 128, 0)));
  homeDieList.add(new Die(0, 225, -150, 100, color(0, 255, 0), color(0, 128, 0)));
  // middle row
  homeDieList.add(new Die(0, -150, 0, 100, color(0, 0, 255), color(128, 192, 255)));
  homeDieList.add(new Die(0, 0, 0, 100, color(64, 0, 128), color(192, 128, 255)));
  homeDieList.add(new Die(0, 150, 0, 100, color(128, 0, 128), color(255, 192, 255)));
  // bottom row
  homeDieList.add(new Die(0, -75, 150, 100, color(255, 255, 255), color(0, 0, 0)));
  homeDieList.add(new Die(0, 75, 150, 100, color(0, 0, 0), color(255, 255, 255)));
  for (int i = 0; i < homeDieList.size(); i++) {
    UIInstance icon = homeDieList.get(i);
    icon.clickable = true;
    homeInstanceList.add(icon);
  }
}

boolean launchStarted = false;

float dmouseX = width / 2.0;
float dmouseY = height / 2.0;

int pmillis = -1;
float seconds = 0;
float deltaSeconds = 0;
float deltaTick = 0;

void setup() {
  size(750, 750, P3D);
  smooth(2);
  rectMode(CENTER);
  frameRate(FRAME_RATE);
}

void draw() {
  updateMouse();
  updateTime();
  updateInstances();

  if (gameOn) {
    physicsStep(deltaSeconds);
    checkDieLanded();
  }
  
  drawWorld();
  drawUI();
}

void updateMouse() {
  dmouseX = mouseX - ((float)width / 2);
  dmouseY = mouseY - ((float)height / 2);
}

void updateTime() {
  if (pmillis == -1) {
    pmillis = millis();
  }
  seconds = millis() / 1000.0;
  deltaSeconds = (millis() - pmillis) / 1000.0;
  deltaTick = deltaSeconds * SIMULATION_RATE;
  pmillis = millis();
}

void updateInstances() {
  int startSize = instanceList.size();
  for (int i = 0; i < startSize; i++) {
    instanceList.get(i - (startSize - instanceList.size())).update();
  }
}

void physicsStep(float deltaTime) {
  for (int i = 0; i < instanceList.size(); i++) {
    Instance instance = instanceList.get(i);
    if (instance instanceof DiePhysicsInstance == false) {
      continue;
    }
    PhysicsInstance physicsInstance = (PhysicsInstance)instance;
    physicsInstance.physicsUpdate(deltaTime);
  }
}

void checkDieLanded() {
  if (die.idle && dieLaunched) {
    int face = die.getTopFace();
    homeDieList.get(correspondingDieButton).n = face;
    endGame();
  }
}

void mousePressed() {
  if (gameOn && Math.hypot(dmouseX, dmouseY) <= DIE_LAUNCH_MOUSE_STARTZONE && dieLaunched == false && die.idle == true) {
    launchStarted = true;
    setLaunchPower();
  }

  for (int i = 0; i < instanceList.size(); i++) {
    Instance instance = instanceList.get(i);
    if (instance instanceof UIInstance == false) {
      continue;
    }
    UIInstance uiInstance = (UIInstance)instance;
    if (uiInstance.clickable && uiInstance.canClick()) {
      uiInstance.onClick();
      break;
    }
  }
}

void mouseDragged() {
  if (gameOn && launchStarted) {
    setLaunchPower();
  }
}

void mouseReleased() {
  if (gameOn && launchStarted) {
    launchStarted = false;
    
    if (dieLaunchPower > 0) {
      float cameraHorizontalAngle = (float)Math.atan2(cameraInstance.center.z - cameraInstance.position.z, cameraInstance.center.x - cameraInstance.position.x);
      float mouseAngle = (float)Math.atan2(dmouseY, dmouseX) - HALF_PI;
      float horizontalAngle = cameraHorizontalAngle + mouseAngle;
      float verticalAngle = radians(70) * -(dieLaunchPower / DIE_LAUNCH_MAX_POWER);
      
      dieLaunched = true;
      die.velocity = new Vector3((float)Math.cos(horizontalAngle), (float)Math.sin(verticalAngle), (float)Math.sin(horizontalAngle)).multiply(dieLaunchPower);
    }
  }
}

void setLaunchPower() {
  if ((dmouseX != 0 || dmouseY != 0) && Math.hypot(dmouseX, dmouseY) >= DIE_LAUNCH_MOUSE_DEADZONE) {
    float bound = Math.min(width, height) / 2 * 0.9;
    float rawLaunchPower = (DIE_LAUNCH_MAX_POWER - DIE_LAUNCH_MIN_POWER) * ((float)Math.hypot(dmouseX, dmouseY)) / bound;
    dieLaunchPower = Math.min(DIE_LAUNCH_MAX_POWER, DIE_LAUNCH_MIN_POWER + rawLaunchPower);
  } else {
    dieLaunchPower = 0;
  }
}

// draw functions
void drawWorld() {
  if (gameOn == false) {
    return;
  }
  hint(ENABLE_DEPTH_TEST);
  float eyeX = cameraInstance.position.x;
  float eyeY = cameraInstance.position.y;
  float eyeZ = cameraInstance.position.z;
  if (Math.abs(eyeX - cameraInstance.center.x) < 5) {
    int eyeSign = mathSign(eyeX - cameraInstance.center.x);
    eyeX = cameraInstance.center.x + 5 * eyeSign;
  }
  if (Math.abs(eyeY - cameraInstance.center.y) < 5) {
    int eyeSign = mathSign(eyeY - cameraInstance.center.y);
    eyeY = cameraInstance.center.y + 5 * eyeSign;
  }
  if (Math.abs(eyeZ - cameraInstance.center.z) < 5) {
    int eyeSign = mathSign(eyeZ - cameraInstance.center.z);
    eyeZ = cameraInstance.center.z + 5 * eyeSign;
  }
  pushMatrix();
  camera(
    eyeX, eyeY, eyeZ,
    cameraInstance.center.x, cameraInstance.center.y, cameraInstance.center.z,
    0, 1, 0
  );
  float fov = PI/3.0;
  pushMatrix();
  translateWorld(cameraInstance.position);
  lights();
  directionalLight(128, 128, 128, -1, 0.2, -1);
  lightFalloff(0.5, 0.00015, 0.0);
  popMatrix();

  perspective(fov, (float)width/(float)height, 4, 640000);
  background(135, 206, 235);
  drawGround();
  drawShadow(die.position);
  
  for (int i = 0; i < instanceList.size(); i++) {
    Instance instance = instanceList.get(i);
    if (instance instanceof PVInstance == false) {
      continue;
    }
    pushMatrix();
    instance.draw();
    popMatrix();
  }

  popMatrix();
}

void drawGround() {
  pushMatrix();
  fill(37, 129, 57);
  stroke(0, 0, 0);
  strokeWeight(12);
  translateWorld(new Vector3(cameraInstance.position.x, FLOOR_POSITION + 16, cameraInstance.position.z));
  rotateX(radians(90));
  float scale = Math.min(Math.max(width, height) * 5.6, 8181);
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

void drawUI() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  pushMatrix();

  // game on ui
  if (gameOn) {
    drawLaunchCharge();
  } else {
    drawHomeScreen();
  }

  for (int i = 0; i < instanceList.size(); i++) {
    Instance instance = instanceList.get(i);
    if (instance instanceof UIInstance == false) {
      continue;
    }
    pushMatrix();
    instance.draw();
    popMatrix();
  }

  popMatrix();
}

void drawHomeScreen() {
  // background
  fill(200, 200, 200);
  noStroke();
  rect(width / 2, height / 2, width, height);

  // total text
  int total = 0;
  for (int i = 0; i < homeDieList.size(); i++) {
    Die instance = homeDieList.get(i);
    total += instance.n;
  }
  homeDiceTotalText.textString = "Total: " + total;
}

void drawLaunchCharge() {
  if (mousePressed && launchStarted) {
    float offsetX = dmouseX;
    float offsetY = dmouseY;
    float magnitude = (float)Math.hypot(offsetX, offsetY);
    float bound = Math.min(width, height) / 2 * 0.9;
    if (magnitude > bound) {
      offsetX = offsetX / magnitude * bound;
      offsetY = offsetY / magnitude * bound;
      magnitude = bound;
    }

    int amt = 10;
    float exp = 0.8;
    float sizeMultiplier = 1.25 - (magnitude / bound);

    noStroke();
    if (dieLaunchPower == 0) {
      fill(255, 0, 0, 100);
    } else {
      fill(255, 255, 255, 150);
    }
    for (int i = 1; i <= amt; i++) {
      float size = sizeMultiplier * (i * 2) + 5;
      float positionScale = (float)Math.pow((float)i / amt, exp);
      ellipse(width / 2 + offsetX * positionScale, height / 2 + offsetY * positionScale, size, size);
    }
  }
}

// utility classes
abstract class Instance {
  
  Instance() {
    instanceList.add(this);
  }

  void update() {}
  
  void draw() {}

  void destroy() {
    instanceList.remove(this);
  }
}

class UIInstance extends Instance {
  float x;
  float y;
  boolean visible;
  boolean clickable;

  UIInstance() {
    super();
    visible = true;
    clickable = false;
  }
  
  void rect(float x, float y, float w, float h) {
    rect(x + this.x + width / 2, y + this.y + height / 2, w, h);
  }

  void ellipse(float x, float y, float w, float h) {
    ellipse(x + this.x + width / 2, y + this.y + height / 2, w, h);
  }

  boolean canClick() {
    return false;
  }

  void onClick() {}
}

class TextInstance extends UIInstance {
  String textString;
  int fontSize;
  color textColor;
  
  TextInstance(String textString, float x, float y, int fontSize, color textColor) {
    super();
    this.textString = textString;
    this.x = x;
    this.y = y;
    this.fontSize = fontSize;
    this.textColor = textColor;
  }
  
  void draw() {
    if (visible == false) {
      return;
    }
    fill(textColor);
    noStroke();
    textAlign(CENTER, CENTER);
    textSize(fontSize);
    text(textString, x + width / 2, y + height / 2);
  }
}

class Die extends UIInstance {
  int n;
  float size;
  color backgroundColor;
  color dotColor;

  Die(int n, float x, float y, float size, color backgroundColor, color dotColor) {
    super();
    this.n = n;
    this.x = x;
    this.y = y;
    this.size = size;
    this.backgroundColor = backgroundColor;
    this.dotColor = dotColor;
  }

  void draw() {
    if (visible == false) {
      return;
    }
    drawDieFace(n, x + width / 2, y + height / 2, size, backgroundColor, dotColor);
  }

  boolean canClick() {
    if (visible == false) {
      return false;
    }
    float screenX = x + width / 2;
    float screenY = y + height / 2;
    return (mouseX >= screenX - size / 2 && mouseX <= screenX + size / 2 && mouseY >= screenY - size / 2 && mouseY <= screenY + size / 2);
  }

  void onClick() {
    if (gameOn) {
      return;
    }
    correspondingDieButton = homeDieList.indexOf(this);
    die.faceColor = backgroundColor;
    die.dotColor = dotColor;
    startGame();
  }
}

class PVInstance extends Instance {
  Vector3 position = new Vector3(0, 0, 0);
  Vector3 rotation = new Vector3(0, 0, 0);

  PVInstance() {
    super();
  }
}

class PhysicsInstance extends PVInstance {
  Vector3 velocity = new Vector3(0, 0, 0);
  Vector3 size = new Vector3(50, 50, 50);

  PhysicsInstance() {
    super();
  }

  void physicsUpdate(float deltaTime) {}
}

class DiePhysicsInstance extends PhysicsInstance {
  boolean grounded;
  boolean idle;
  color faceColor;
  color dotColor;
  
  DiePhysicsInstance() {
    super();
    grounded = false;
    idle = false;
    faceColor = color(255, 255, 255);
    dotColor = color(0, 0, 0);
  }
  
  void draw() {
    if (position.subtract(cameraInstance.position).magnitude() < size.magnitude()) {
      return;
    }
    fill(faceColor);
    stroke(dotColor);
    strokeWeight(4);
    translateWorld(position);
    rotateWorld(rotation);
    boxWorld(this.size);

    int lift = 1;
    // 1
    pushMatrix();
    translate(0, 0, size.z / 2 + lift);
    drawDieDots(1, 0, 0, size.average(), dotColor);
    popMatrix();
    // 2
    pushMatrix();
    translate(size.x / 2 + lift, 0, 0);
    rotateY(-HALF_PI);
    drawDieDots(2, 0, 0, size.average(), dotColor);
    popMatrix();
    // 3
    pushMatrix();
    translate(0, -size.y / 2 - lift, 0);
    rotateX(-HALF_PI);
    rotate(HALF_PI);
    drawDieDots(3, 0, 0, size.average(), dotColor);
    popMatrix();
    // 4
    pushMatrix();
    translate(0, size.y / 2 + lift, 0);
    rotateX(HALF_PI);
    drawDieDots(4, 0, 0, size.average(), dotColor);
    popMatrix();
    // 5
    pushMatrix();
    translate(-size.z / 2 - lift, 0, 0);
    rotateY(HALF_PI);
    drawDieDots(5, 0, 0, size.average(), dotColor);
    popMatrix();
    // 6
    pushMatrix();
    translate(0, 0, -size.z / 2 - lift);
    rotateX(PI);
    drawDieDots(6, 0, 0, size.average(), dotColor);
    popMatrix();
  }

  void physicsUpdate(float deltaTime) {
    rotation = rotation.normalize(TWO_PI);
    velocity.y += GRAVITY * deltaTime;
    position = position.add(velocity.multiply(deltaTime));

    float boundRadius = size.average() / 2;

    if (position.y >= FLOOR_POSITION - boundRadius) {
      position.y = FLOOR_POSITION - boundRadius;
      grounded = true;

      Vector3 error = getUprightRotation().subtract(rotation);
      float cut = Math.max(1, Math.max(Math.min(6, velocity.multiplyVector(new Vector3(1, 0, 1)).magnitude() / 10), 3) / deltaTick);
      rotation = rotation.add(error.divide(cut));

      idle = velocity.multiplyVector(new Vector3(1, 0, 1)).magnitude() < DIE_STOP_SPEED_THRESHOLD && velocity.y <= GRAVITY * deltaTime + 1;
      if (idle) {
        velocity = new Vector3(0, 0, 0);
      } else {
        velocity.y *= -0.3;
      }

      float friction = 1 / (1 + ((deltaTime * SIMULATION_RATE) * 0.3));
      velocity.x *= friction;
      velocity.z *= friction;
    } else {
      rotation = rotation.add(velocity.multiply(deltaTime).multiply(0.01).absolute());
      grounded = false;
      idle = false;
    }
  }

  Vector3 getUprightRotation() {
    return rotation.divide(HALF_PI).round().multiply(HALF_PI);
  }

  int getTopFace() {
    Vector3 uprightRotation = getUprightRotation().normalize(TWO_PI);
    Vector3 lookVector = new Vector3(
      (float)(Math.cos(uprightRotation.y) * Math.cos(uprightRotation.x)),
      (float)(Math.sin(uprightRotation.x)),
      (float)(Math.sin(uprightRotation.y) * Math.cos(uprightRotation.x))
    ).round();
    boolean exceptionCase = (mathFuzzyEq((uprightRotation.x - HALF_PI) % PI, 0, 1) || mathFuzzyEq((uprightRotation.x - HALF_PI) % PI, PI, 1)) && (mathFuzzyEq((uprightRotation.y - HALF_PI) % PI, 0, 1) || mathFuzzyEq((uprightRotation.y - HALF_PI) % PI, PI, 1));
    if (lookVector.x == 1 || lookVector.x == -1 || lookVector.z == 1 || lookVector.z == -1 || exceptionCase) {
      float angle = uprightRotation.z;
      if ((lookVector.x != 0 && mathFuzzyEq(uprightRotation.x, PI, 1)) || (lookVector.z != 0 && mathFuzzyEq(uprightRotation.x, PI, 1))) {
        angle = mathNormalize(PI + angle, TWO_PI);
      }
      if (exceptionCase) {
        angle = mathNormalize(HALF_PI + angle, TWO_PI);
        if (mathFuzzyEq(uprightRotation.x, uprightRotation.y, 1) == false) {
          angle = mathNormalize(PI + angle, TWO_PI);
        }
      }
      if (mathFuzzyEq(angle, 0, 1)) {
        return 3;
      }
      if (mathFuzzyEq(angle, HALF_PI, 1)) {
        return 5;
      }
      if (mathFuzzyEq(angle, PI, 1)) {
        return 4;
      }
      if (mathFuzzyEq(angle, PI + HALF_PI, 1)) {
        return 2;
      }
    }
    if (lookVector.y == 1 || lookVector.y == -1) {
      float angle = uprightRotation.y;
      if (mathFuzzyEq(uprightRotation.x, PI + HALF_PI, 1)) {
        angle = mathNormalize(PI - angle, TWO_PI);
      }
      if (mathFuzzyEq(angle, 0, 1)) {
        return 1;
      }
      if (mathFuzzyEq(angle, HALF_PI, 1)) {
        return 5;
      }
      if (mathFuzzyEq(angle, PI, 1)) {
        return 6;
      }
      if (mathFuzzyEq(angle, PI + HALF_PI, 1)) {
        return 2;
      }
    }
    return 0;
  }
}

class CameraInstance extends PVInstance {
  Vector3 center;

  CameraInstance() {
    center = new Vector3(0, 0, 0);
  }

  void update() {
    Vector3 pcenter = center.copy();
    center = center.add(die.position.subtract(center).divide(Math.max(1, 20 / deltaTick)));
    Vector3 centerVelocity;
    if (deltaSeconds == 0) {
      centerVelocity = new Vector3(0, 0, 0);
    } else {
      centerVelocity = center.subtract(pcenter).divide(deltaSeconds);
    }
    if (die.idle) {
      Vector3 goalPosition = new Vector3(1000 * (float)Math.sin(seconds), 300 + 200 * (float)Math.sin(seconds), 1000 * (float)Math.cos(seconds));
      position = position.add(center.subtract(position).subtract(goalPosition).divide(Math.max(1, 10 / deltaTick)));
    } else {
      Vector3 goalPosition = centerVelocity.unit().multiply(1000).add(new Vector3(0, 250, 0));
      position = position.add(center.subtract(position).subtract(goalPosition).divide(Math.max(1, 25 / deltaTick)));
    }
    if (position.y > FLOOR_POSITION - 25) {
      position.y = FLOOR_POSITION - 25;
    }
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

  Vector3 addVector(Vector3 otherVector) {
    return new Vector3(x + otherVector.x, y + otherVector.y, z + otherVector.z);
  }

  Vector3 multiplyVector(Vector3 otherVector) {
    return new Vector3(x * otherVector.x, y * otherVector.y, z * otherVector.z);
  }

  Vector3 normalize(float range) {
    return new Vector3(mathNormalize(x, range), mathNormalize(y, range), mathNormalize(z, range));
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

// utility functions
void startGame() {
  for (int i = 0; i < homeInstanceList.size(); i++) {
    UIInstance instance = homeInstanceList.get(i);
    instance.clickable = false;
    instance.visible = false;
  }

  dieLaunched = false;
  die.position.x = 0;
  die.position.y = die.size.magnitude();
  die.position.z = 0;
  die.velocity = new Vector3(0, 0, 0);
  die.rotation = new Vector3((float)Math.random() * TWO_PI, (float)Math.random() * TWO_PI, (float)Math.random() * TWO_PI);
  cameraInstance.center = die.position;
  cameraInstance.position = new Vector3(0, -6000, -5000);
  launchStarted = false;
  gameOn = true;
}

void endGame() {
  for (int i = 0; i < homeInstanceList.size(); i++) {
    UIInstance instance = homeInstanceList.get(i);
    instance.clickable = true;
    instance.visible = true;
  }
  gameOn = false;
}

int mathSign(float n) {
  if (n == 0) {
    return 0;
  }
  return (int)(n / Math.abs(n));
}

boolean mathFuzzyEq(float a, float b, float precision) {
  return Math.abs(a - b) <= precision;
}

float mathNormalize(float n, float range) {
  if (n < 0) {
    return range - (Math.abs(n) % range);
  }
  return n % range;
}

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

void drawDieFace(int n, float x, float y, float size, color backgroundColor, color dotColor) {
  fill(backgroundColor);
  noStroke();
  rect(x, y, size, size);
  if (n > 0) {
    drawDieDots(n, x, y, size, dotColor);
  }
}

void drawDieDots(int n, float x, float y, float size, color dotColor) {
  fill(dotColor);
  noStroke();
  float dotSize = size / 5;
  if (n == 1 || n == 3 || n == 5) {
    ellipse(x, y, dotSize, dotSize);
  }
  if (n >= 2) {
    ellipse(x - size / 4, y - size / 4, dotSize, dotSize);
    ellipse(x + size / 4, y + size / 4, dotSize, dotSize);
  }
  if (n >= 4) {
    ellipse(x - size / 4, y + size / 4, dotSize, dotSize);
    ellipse(x + size / 4, y - size / 4, dotSize, dotSize);
  }
  if (n == 6) {
    ellipse(x - size / 4, y, dotSize, dotSize);
    ellipse(x + size / 4, y, dotSize, dotSize);
  }
}