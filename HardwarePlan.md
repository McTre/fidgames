# FidGames Hardware Plan

## Main Board

LILYGO T-Display-S3

Features:
- ESP32-S3
- 1.9 inch display
- USB-C
- Bluetooth
- WiFi

## Form Factor

Goals:

- Keychain sized
- Pocket friendly
- One-handed operation

Typical orientation:

- Portrait display
- Slider below display
- Trigger button on rear
- Lock button on side or top

## Primary Control

### Magnetic Analog Slider

Characteristics:

- Left position
- Center position
- Right position
- Magnetic self-centering
- Hall-effect sensing
- Analog output

Benefits:

- No wear
- Pleasant tactile feel
- Silent operation
- Fidget friendly

### Hall Sensors

Preferred:

- Dual linear Hall sensors

Benefits:

- Better center stability
- Temperature compensation
- Improved precision

## Rear Button

Purpose:

- Primary action
- Trigger-style operation

## Motion Sensor

Recommended:

- BMI270

Uses:

- Shake detection
- Tilt detection
- Gesture events

Gyro is a secondary input only.

## Haptics

Preferred:

- LRA actuator
- DRV2605L driver

Purpose:

- Event feedback
- Game feel
- Silent notifications

Not intended for continuous vibration.

## Power

Battery:

- Small LiPo cell

Goals:

- Long standby life
- Instant wake
- Efficient sleep modes

## Future Possibilities

- Bluetooth score sharing
- Daily challenges
- Additional magnetic controls
- Charging dock
