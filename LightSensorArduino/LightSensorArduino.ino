int value; 
void setup() {
  // put your setup code here, to run once:
Serial.begin(9600);
}

void loop() {
  // put your main code here, to run repeatedly:
  value = analogRead(0);
  Serial.print(value);
  Serial.print('a');
  delay(1);
}
