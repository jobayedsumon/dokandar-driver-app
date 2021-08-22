import 'package:driver/Account/UI/account_page.dart';
import 'package:driver/Auth/login_navigator.dart';
import 'package:driver/Locale/locales.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setFirebase();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool result = prefs.getBool('islogin');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: kMainTextColor.withOpacity(0.5),
  ));
  runApp(
      Phoenix(child: (result != null && result) ? GomarketHome() : Gomarket()));
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void setFirebase() async {
  FirebaseMessaging messaging = FirebaseMessaging();
  iosPermission(messaging);
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid =
      AndroidInitializationSettings('logo_user');
  var initializationSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);
  messaging.getToken().then((value) {
    debugPrint('token: ' + value);
  });
  messaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _showNotification(
            flutterLocalNotificationsPlugin,
            '${message['notification']['title']}',
            '${message['notification']['body']}');
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {},
      onResume: (Map<String, dynamic> message) async {});
}

Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  _showNotification(flutterLocalNotificationsPlugin, '${title}', '${body}');
}

Future<void> _showNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    dynamic title,
    dynamic body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('4579', 'Notify', 'Notify On Shopping',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const IOSNotificationDetails iOSPlatformChannelSpecifics =
      IOSNotificationDetails(presentSound: false);
  IOSNotificationDetails iosDetail = IOSNotificationDetails(presentAlert: true);

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, '${title}', '${body}', platformChannelSpecifics,
      payload: 'item x');
}

Future selectNotification(String payload) async {
  if (payload != null) {}
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  _showNotification(
      flutterLocalNotificationsPlugin,
      '${message['notification']['title']}',
      '${message['notification']['body']}');
}

void iosPermission(firebaseMessaging) {
  firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(sound: true, badge: true, alert: true));
  firebaseMessaging.onIosSettingsRegistered.listen((event) {
    print('${event.provisional}');
  });
}

class Gomarket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('hi'),
      ],
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: LoginNavigator(),
      routes: PageRoutes().routes(),
    );
  }
}

class GomarketHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('hi'),
      ],
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: AccountPage(),
      routes: PageRoutes().routes(),
    );
  }
}
