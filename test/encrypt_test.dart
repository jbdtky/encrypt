import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:test/test.dart';

void main() {
  const text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';
  final key = Key.fromUtf8('my32lengthsupersecretnooneknows1');

  group('Fernet', () {
    final currentDateTime =
        DateTime.fromMillisecondsSinceEpoch(1565106118 * 1000);
    final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
    final fernet = Fernet(b64key, clock: Clock.fixed(currentDateTime));
    final encrypter = Encrypter(fernet);
    final encrypted = Encrypted(base64.decode(
        'gAAAAABdSZ_GAAAAAAAAAAAAAAAAAAAAAP-kE5Zs_CyDB-8I8c26Iz9B78L6hleGlXZmqEjZh107U3ny9yRp8QUAc243_B7q0ZtFFs0xAoJDveTPXwTwvzCwXEd8I9NZ1fZeknZmJkEPRxEsJBh9K5QrqjR8B0Shyg=='));
    final iv = IV.fromLength(16);
    test('encrypt', () {
      expect(encrypter.encrypt(text, iv: iv), equals(encrypted));
      // iv will be generated if not provided
      final encryptedAgain = encrypter.encrypt(text);
      expect(encrypter.decrypt(encryptedAgain), equals(text));
    });
    test('decrypt', () {
      expect(encrypter.decrypt(encrypted), equals(text));
      expect(fernet.extractTimestamp(encrypted.bytes), equals(1565106118));
    });
  });

  group('AES', () {
    const <AESMode, String>{
      AESMode.cbc:
          '2wZs4YD2LwIGF+tyC4kcHocGhO/6jh5ajv+QnzdUSeU54YAVXVO7t1nw3GTbHbQN03vpQatXfDkWzCkRb7fbdA==',
      AESMode.cfb64:
          'DIXikIUegcuzesmInMboN5gdeD6bwV082kZl+lXFGZJCIti39JSobQ0iEvsnTPSvyuDZ+d3HxXE=',
      AESMode.ctr:
          'DIXikIUegcvoS6qSszWXgGkVga1GE6a+WkO24Srn1xtc9wtqN4QzWen95c7w2vy7NzMs+fQGPgQ5e/WesjaSng==',
      AESMode.ecb:
          '2wZs4YD2LwIGF+tyC4kcHvzEiyF8uDJygSqO/jsw5+rkNz3c7eTqd72ud9Em2VRXELSobpNiPJWAiwr561Teog==',
      AESMode.ofb64Gctr:
          'zOBn8gU5GXZ7LSrPcSs8ejAzOxL0DKfFoZtG2a3NqNbyJqTIDmKPfau3Yl3/l7X4iotfYKULTRE=',
      AESMode.ofb64:
          'DIXikIUegcuyEelB4En11TiUpnGRJNvFZIr3oxcCQ2XlYoplQpVYOrPOLCfvJ3P04kS9s/rITFE=',
      AESMode.sic:
          'DIXikIUegcvoS6qSszWXgGkVga1GE6a+WkO24Srn1xtc9wtqN4QzWen95c7w2vy7NzMs+fQGPgQ5e/WesjaSng==',
    }.forEach((mode, encoded) {
      group('$mode', () {
        final encrypter = Encrypter(AES(key, mode: mode));
        final encrypted = Encrypted(base64.decode(encoded));

        test('encrypt', () {
          expect(encrypter.encrypt(text, iv: IV.fromLength(16)),
              equals(encrypted));
        });

        test('decrypt', () {
          expect(encrypter.decrypt(encrypted, iv: IV.fromLength(16)),
              equals(text));
        });
      });
    });
  });

  group('AES (no padding)', () {
    const <AESMode, String>{
      AESMode.cbc:
          '2wZs4YD2LwIGF+tyC4kcHocGhO/6jh5ajv+QnzdUSeU54YAVXVO7t1nw3GTbHbQNNh/ViBlFFQZ0nMTBMcWqGw==',
      AESMode.cfb64:
          'DIXikIUegcuzesmInMboN5gdeD6bwV082kZl+lXFGZJCIti39JSobQ0iEvsnTPSvyuDZ+d3HxVCKVva0YfIp3w==',
      AESMode.ecb:
          '2wZs4YD2LwIGF+tyC4kcHvzEiyF8uDJygSqO/jsw5+rkNz3c7eTqd72ud9Em2VRXmh2wAvbvFo4pO2LVwwW9og==',
      AESMode.ofb64Gctr:
          'zOBn8gU5GXZ7LSrPcSs8ejAzOxL0DKfFoZtG2a3NqNbyJqTIDmKPfau3Yl3/l7X4iotfYKULTTDrH+mnJ0rm7w==',
      AESMode.ofb64:
          'DIXikIUegcuyEelB4En11TiUpnGRJNvFZIr3oxcCQ2XlYoplQpVYOrPOLCfvJ3P04kS9s/rITHCDPcjZ7QT28g==',
    }.forEach((mode, encoded) {
      group('$mode', () {
        final encrypter = Encrypter(AES(key, mode: mode, padding: null));
        final encrypted = Encrypted(base64.decode(encoded));

        test('encrypt', () {
          expect(encrypter.encrypt(text.padRight(64), iv: IV.fromLength(16)),
              equals(encrypted));
        });

        test('decrypt', () {
          expect(encrypter.decrypt(encrypted, iv: IV.fromLength(16)),
              equals(text.padRight(64)));
        });
      });
    });

    group('Streamables', () {
      const <AESMode, String>{
        AESMode.ctr:
            'DIXikIUegcvoS6qSszWXgGkVga1GE6a+WkO24Srn1xtc9wtqN4QzWen95c7w2vy7NzMs+fQGPg==',
        AESMode.sic:
            'DIXikIUegcvoS6qSszWXgGkVga1GE6a+WkO24Srn1xtc9wtqN4QzWen95c7w2vy7NzMs+fQGPg==',
      }.forEach((mode, encoded) {
        group('$mode', () {
          final encrypter = Encrypter(AES(key, mode: mode, padding: null));
          final encrypted = Encrypted(base64.decode(encoded));

          test('encrypt', () {
            expect(encrypter.encrypt(text, iv: IV.fromLength(16)),
                equals(encrypted));
          });

          test('decrypt', () {
            expect(encrypter.decrypt(encrypted, iv: IV.fromLength(16)),
                equals(text));
          });
        });
      });
    });
  });

  group('Salsa20', () {
    const encoded =
        '2FCmbbVYQrbLn8pkyPe4mt0ooqNRA8Dm9EmzZVSWgW+M/6FembxLmVdt9/JJt+NSMnx1hNjuOw==';

    final encrypter = Encrypter(Salsa20(key));
    final encrypted = Encrypted(base64.decode(encoded));

    test(
        'encrypt',
        () => expect(
            encrypter.encrypt(text, iv: IV.fromLength(8)), equals(encrypted)));

    test(
        'decrypt',
        () => expect(
            encrypter.decrypt(encrypted, iv: IV.fromLength(8)), equals(text)));
  });

  group('RSA', () {
    final parser = RSAKeyParser();
    final RSAPublicKey publicKey = parser
        .parse(File('test/public.pem').readAsStringSync()) as RSAPublicKey;
    final RSAPrivateKey privateKey = parser
        .parse(File('test/private.pem').readAsStringSync()) as RSAPrivateKey;

    RSAEncoding.values.forEach((encoding) {
      final encrypter = Encrypter(RSA(
          publicKey: publicKey, privateKey: privateKey, encoding: encoding));
      final encrypted = encrypter.encrypt(text);

      test('encrypt/decrypt $encoding', () {
        expect(encrypter.decrypt(encrypted), equals(text));
      });
    });

    group('StateError', () {
      final badStateEncrypter = Encrypter(RSA());

      test('encrypt', () {
        expect(() => badStateEncrypter.encrypt(text), throwsStateError);
      });

      test('decrypt', () {
        final encrypted = Encrypted.fromLength(0);
        expect(() => badStateEncrypter.decrypt(encrypted), throwsStateError);
      });
    });
  });
}
