# Lumen Control

Turn LEDs wired to an Arduino on and off from an Android phone over Bluetooth.
A Flutter app sends short text commands through an HC-05 Bluetooth serial module,
and the Arduino sketch drives 12 LEDs arranged in three groups of four.

**Status: hardware prototype.** It is a demo of phone-to-microcontroller control,
not a tested product, and it makes no claims about reliability, range or latency.

## How it works

```
Flutter app (Android)
  flutter_bluetooth_serial
        |
        |  Bluetooth Classic, text lines ending in \r\n
        v
HC-05 module  --TXD-->  Arduino pin 2 (RX)   SoftwareSerial, 9600 baud
              <--RXD--  Arduino pin 3 (TX)
        |
        v
Arduino sketch (control_light.ino)
  Block 1 -> pins 4, 5, 6, 7
  Block 2 -> pins 8, 9, 10, 11
  Block 3 -> pins 12, 13, A0, A1
  Link LED -> pin A2
```

1. The app connects to the module by MAC address or device name.
2. Every toggle in the UI becomes one text line: `block-<block>-<led>-<state>`.
3. The sketch reads the line on pins 2/3, sets one output pin HIGH or LOW and
   answers `OK ...` or `ERR ...` on both the Bluetooth link and the USB serial port.
4. While connected, the app sends `ping` every 2 seconds. Incoming data keeps the
   sketch's link timer alive, and the link LED on A2 blinks while the link is up.

### Command protocol

Both serial ports run at 9600 baud. A line ends at `\n` or `\r` (the app sends
`\r\n`). The sketch trims whitespace and drops the buffer if a line grows past
64 characters. It splits the line on `-` and does not check the word before the
first dash.

| Direction | Message | Meaning |
|---|---|---|
| app -> board | `block-<b>-<i>-<s>` | Set LED `i` of block `b`. `b` is 1..3 (1-based), `i` is 0..3 (0-based), `s` is `1` for on, `0` for off. Example: `block-2-3-1` sets pin 11 HIGH. |
| app -> board | `ping` | Heartbeat. |
| board -> app | `pong` | Reply to `ping`. |
| board -> app | `OK <b>-<i>-><s>` | Command applied, for example `OK 2-3->1`. |
| board -> app | `ERR format` | The line has fewer than three `-` separators. |
| board -> app | `ERR addr` | Block is not 1..3 or LED index is not 0..3. |
| board -> app | `ERR state` | State is not `0` or `1`. |

The app labels the lights "LED 1" to "LED 4"; on the wire the same lights are
index 0 to 3.

### Heartbeat and link LED

- **App:** a 2-second `Timer.periodic` writes `ping\r\n` while the connection is open.
- **Sketch:** any received byte (not only `ping`) resets the link timer. While the
  last byte arrived no more than `heartbeatTimeout` (10,000 ms) ago, the LED on A2
  toggles every `blinkInterval` (500 ms). After that it stays LOW. The timer also
  starts at power-up, so the LED blinks for the first 10 seconds after boot even
  before anything connects.
- The light pins are not reset when the link drops. They keep their last state.
- The app does not read the board's replies (`pong`, `OK`, `ERR`). It treats
  the link as lost when the Bluetooth input stream closes or a send fails.

## Wiring

The pin map below is copied from `control_light/arduino/control_light.ino`.

**Lights** (`blockPins[3][4]`):

| Block (protocol `b`) | App name | LED 0 | LED 1 | LED 2 | LED 3 |
|---|---|---|---|---|---|
| 1 | Block A | 4 | 5 | 6 | 7 |
| 2 | Block B | 8 | 9 | 10 | 11 |
| 3 | Block C | 12 | 13 | A0 | A1 |

**Serial link and indicator:**

| Arduino pin | Connects to | In the sketch |
|---|---|---|
| 2 | Bluetooth module TXD (Arduino receives) | `SoftwareSerial btSerial(2, 3); // RX, TX` |
| 3 | Bluetooth module RXD (Arduino transmits) | same |
| A2 | Link indicator LED | `LINK_LED_PIN` |

Notes:

- All 13 LED pins are plain digital outputs set LOW in `setup()`. Each one is
  switched on or off with `digitalWrite`; there is no dimming.
- The sketch does not name a board. It uses digital pins 2 and 3 for the
  SoftwareSerial link and pins 4 to 13 plus A0 to A2 as outputs, which matches
  the common Uno/Nano pin layout.
- Power wiring is not part of the sketch. Take VCC, GND and the RXD logic level
  from your Bluetooth module's datasheet, and put a current-limiting resistor in
  series with each LED.
- Every reply is also printed on the USB serial port (`Serial`, 9600 baud), which
  makes the Arduino IDE Serial Monitor useful for debugging.

## App features

Everything listed here is in `control_light/lib/`.

- **Sign in and create account.** Local accounts only, held in memory by
  `AuthController`. A new sign-up gets the Operator role and no block access
  until an admin grants it. A demo admin login is built in
  (`lib/controllers/auth_controller.dart`, prefilled in
  `lib/features/auth/presentation/auth_flow.dart`). The demo login is for local
  testing; change it before any real use.
- **Roles.** Admin and Operator. Admins control every block; operators control
  only the blocks they have been granted.
- **Control panel.** Three block cards (Block A, B, C), each with four LED toggles
  and a switch for the whole block. Blocks without access show "Locked" and
  reject taps. A summary card shows how many lights are on and has a
  "Turn all off" button.
- **Connection card.** Type a MAC address or device name, or leave the field
  empty to use the default module set in code, then tap Connect. A status line
  shows scanning, connecting, connected, the last payload sent and errors.
- **Simulated mode.** Until a module is connected, toggles update the UI and show
  `Simulated send: <payload>` instead of transmitting, so the interface can be
  tried without hardware.
- **Admin panel** (admins only). Lists users; adds a user with a temporary
  password and chosen block access; switches a user between Admin and Operator
  by tapping the role chip; grants or revokes access per block; deletes users
  (except the signed-in one).
- **Profile.** Name, email, role, an access map per block and a snapshot of block
  count, lights on and Live/Sim mode. Sign out.
- **Theme.** Dark by default, with a light/dark toggle in the app bar. The app is
  locked to portrait.

### What Connect does

`BluetoothManager.connect` in `lib/services/bluetooth_manager.dart`:

1. Requests Bluetooth scan, Bluetooth connect and location permissions.
2. Asks the user to switch Bluetooth on if it is off.
3. Looks for the target among paired devices first. If it is not there, runs
   discovery for up to 10 seconds, matching by address or name.
4. Pairs the device if it is not bonded yet. When the pairing request comes from
   the target address, the pairing handler answers with the PIN set in code.
5. Opens the serial connection and starts the 2-second `ping`.

The default module address, name and pairing PIN are constants at the top of
`bluetooth_manager.dart` (`_defaultAddress`, `_defaultName`, `_defaultPin`), and
the hint text in `lib/features/control/presentation/control_panel_page.dart`
repeats the address and name. Set them to your own module's values.

## Stack

- Flutter and Dart (SDK constraint `^3.9.2`)
- [flutter_bluetooth_serial](https://pub.dev/packages/flutter_bluetooth_serial) `^0.4.0` for the Bluetooth serial link
- permission_handler (runtime permissions), provider (state), flutter_animate and google_fonts (UI)
- Arduino C++ with the SoftwareSerial library

## Run it

### 1. Flash the board

1. Wire the module and LEDs as shown in [Wiring](#wiring).
2. Open `control_light/arduino/control_light.ino` in the Arduino IDE, pick your
   board and port, and upload. The IDE expects a sketch to sit in a folder with
   the same name, so it may offer to move the file into a `control_light` folder.
3. Optional: open the Serial Monitor at 9600 baud. On boot the sketch prints
   `Multi-block on/off controller ready (SoftSerial 2/3)`, then one `OK` or `ERR`
   line per command.

### 2. Pair the module

Pair the HC-05 with the phone in Android's Bluetooth settings, or let the app
pair it on the first Connect. If you want the empty-field shortcut to reach your
module, update the defaults in `bluetooth_manager.dart` first.

### 3. Run the app on Android

You need the Flutter SDK and a physical Android phone with Bluetooth and USB
debugging enabled.

```bash
cd control_light
flutter pub get
flutter run    # select the Android phone
```

Sign in, open **Control**, enter the module's MAC address or name (or leave it
empty for the default) and tap **Connect**. When the card reads "HC-05 connected",
the link LED on A2 starts blinking and the toggles switch the pins.

The Bluetooth part is Android-only: the permissions are declared in
`android/app/src/main/AndroidManifest.xml`, while the iOS, web and desktop
targets have no Bluetooth setup.

## Known limitations

- Users, roles and access rights live in memory, so restarting the app resets
  them. Passwords are stored and compared as plain text.
- The app does not read replies from the board, so the UI shows the requested
  state, not a confirmed one. After an app restart the UI starts with every light
  off, while the board keeps its last pin states.
- The "Turn all off" button on the summary card does not check block permissions.
- In `test/widget_test.dart` the `pumpWidget` call is commented out, so the test
  does not exercise the app yet.

## Repository layout

```
control_light/                          Flutter project root
  arduino/control_light.ino             Arduino sketch: pin map, command parser, heartbeat
  lib/
    main.dart, app.dart                 entry point, providers, MaterialApp and themes
    services/bluetooth_manager.dart     permissions, discovery, pairing, send, ping
    controllers/                        auth (local users, roles), lights (3 x 4 state), theme
    models/                             LightBlock, UserAccount
    features/                           auth, dashboard shell, control, admin and profile screens
    core/                               theme colors, glass card, animated background, helpers
  android/                              Android host app, Bluetooth permissions in the manifest
  ios/ macos/ linux/ windows/ web/      other Flutter platform folders (no Bluetooth setup)
  test/widget_test.dart                 placeholder widget test
```

## Author

Adilkan Anarbekov, web and Flutter developer from Bishkek, Kyrgyzstan.
[adilkan.com](https://adilkan.com) · [GitHub](https://github.com/adilkananarbekov)
