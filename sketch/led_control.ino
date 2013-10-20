void setup()
{
  Serial.begin(115200);
  
  pinMode(13, OUTPUT);
}

void loop()
{
  if (Serial.available() > 0) {
    if (Serial.read() == '0') {
      digitalWrite(13, LOW);
    }
    else {
      digitalWrite(13, HIGH);
    }   
  }
}
