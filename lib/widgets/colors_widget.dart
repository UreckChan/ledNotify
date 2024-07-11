import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart'
    as servicecontrol;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class ColorsWidget extends StatefulWidget {
  final Function(String) sendData;
  ColorsWidget({required this.sendData});
  @override
  _ColorsWidgetState createState() => _ColorsWidgetState();
}

Future<String> getAccessToken() async {
  // Cargar el archivo JSON desde los activos
  final String response =
      await rootBundle.loadString('assets/notifications.json');
  final serviceAccountJson = json.decode(response);

  List<String> scopes = [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/firebase.database",
    "https://www.googleapis.com/auth/firebase.messaging"
  ];

  http.Client client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
  );

  // Obtener el token de acceso
  auth.AccessCredentials credentials =
      await auth.obtainAccessCredentialsViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
    client,
  );

  // Cerrar el cliente HTTP
  client.close();

  // Devolver el token de acceso
  return credentials.accessToken.data;
}

class _ColorsWidgetState extends State<ColorsWidget> {
  Future<void> sendFCMMessage(value) async {
    final String serverKey =
        await getAccessToken(); // Tu clave del servidor FCM
    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/notifications-c339c/messages:send';
    final Map<String, dynamic> message = {
      'message': {
        'topic': 'allDevices', // El nombre del topic
        'notification': {
          'body': (value ? "Encendido" : "Apagado"),
          'title': (value ? "Led Encendido" : "Led Apagado")
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
      print(message);
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }

  bool _switchValue = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(),
          const SizedBox(height: 25),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _switchValue ? 'Apagar' : 'Encender',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _switchValue,
                    onChanged: (value) {
                      sendFCMMessage(value);
                      AwesomeNotifications().createNotification(
                        content: NotificationContent(
                          id: 1,
                          channelKey: "basic_channel",
                          title: (value ? "Led Encendido" : "Led Apagado"),
                          body: (value ? "Encendido" : "Apagado"),
                        ),
                      );
                      setState(() {
                        _switchValue = value;
                      });
                      widget.sendData(value ? "T" : "F");
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
