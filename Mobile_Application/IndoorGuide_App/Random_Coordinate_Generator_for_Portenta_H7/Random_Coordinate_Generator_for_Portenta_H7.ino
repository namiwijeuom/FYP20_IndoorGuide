void setup() {
  // Initialize serial communication at 9600 baud rate
  Serial.begin(115200);
  while (!Serial) {
    ; // Wait for serial port to connect. Needed for native USB port only
  }
}

void loop() {
  // Generate random latitude and longitude
  float X = random(0, 21);
  float Y = random(0, 21);

  // Create a JSON string manually
  String jsonString = "{\"X\":" + String(X, 6) + ",\"Y\":" + String(Y, 6) + "}";

  // Send the JSON string over the serial port
  Serial.println(jsonString);

  // Wait for a second before sending the next set of coordinates
  delay(1000);
}