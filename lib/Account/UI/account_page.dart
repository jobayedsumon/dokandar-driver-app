import 'dart:async';
import 'dart:convert';

import 'package:animated_widgets/widgets/rotation_animated.dart';
import 'package:animated_widgets/widgets/shake_animated_widget.dart';
import 'package:driver/Auth/login_navigator.dart';
import 'package:driver/Components/list_tile.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/dutyonoff.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boom_menu/flutter_boom_menu.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

var scfoldKey = GlobalKey<ScaffoldState>();

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin {
  Completer<GoogleMapController> _controller = Completer();
  var onOffLine = 'GO OFFLINE';
  var status = 0;
  dynamic lat;
  dynamic lng;
  SharedPreferences preferences;
  dynamic driverName = '';
  dynamic driverNumber = '';
  dynamic imageUrld = '';
  static const LatLng _center = const LatLng(0, 0);
  CameraPosition kGooglePlex = CameraPosition(
    target: _center,
    zoom: 12.151926,
  );
  bool isRun = false;
  bool isRingBell = false;
  Timer timer;
  var orderCount = 0;

  @override
  void initState() {
    super.initState();
    getCurrency();
    _getLocation();
    getSharedPref();
    hitStatusServiced();
    setTimerTask();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer.cancel();
    }
    super.dispose();
  }

  void setTimerTask() async {
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (this.timer == null) {
        this.timer = timer;
      }
      hitTestServices();
    });
  }

  void hitStatusServiced() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    print('${status} - ${preferences.getInt('delivery_boy_id')}');
    var client = http.Client();
    var statusUrl = driverstatus;
    client.post(statusUrl, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}'
    }).then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          var sat = jsonData['data']['delivery_boy_status'];
          print('${sat}');
          if (sat == "online") {
            var lat = preferences.getDouble('lat');
            var lng = preferences.getDouble('lng');
            setLocation(lat, lng);
            preferences.setInt('duty', 1);
            setState(() {
              status = 1;
            });
          } else {
            preferences.setInt('duty', 0);
            setState(() {
              status = 0;
            });
          }
        }
      }
    }).catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }

  void _getLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      bool isLocationServiceEnableds =
          await Geolocator.isLocationServiceEnabled();
      if (isLocationServiceEnableds) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print(position);
        Timer(Duration(seconds: 5), () async {
          double lat = position.latitude;
          double lng = position.longitude;
          print("LAT, LONG: ");
          print(lat);
          print(lng);
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          setLocation(lat, lng);
        });
        Geolocator.getPositionStream(distanceFilter: 1, timeInterval: 15)
            .listen((positionNew) {
          print(positionNew == null
              ? 'Unknown'
              : positionNew.latitude.toString() +
                  ', ' +
                  positionNew.longitude.toString());
          double lat = positionNew.latitude;
          double lng = positionNew.longitude;
          prefs.setString("lat", lat.toStringAsFixed(8));
          prefs.setString("lng", lng.toStringAsFixed(8));
          setLocation(lat, lng);
        });
      } else {
        await Geolocator.openLocationSettings().then((value) {
          if (value) {
            _getLocation();
          } else {
            Toast.show('Location permission is required!', context,
                duration: Toast.LENGTH_SHORT);
          }
        }).catchError((e) {
          Toast.show('Location permission is required!', context,
              duration: Toast.LENGTH_SHORT);
        });
      }
    } else if (permission == LocationPermission.denied) {
      LocationPermission permissiond = await Geolocator.requestPermission();
      if (permissiond == LocationPermission.whileInUse ||
          permissiond == LocationPermission.always) {
        _getLocation();
      } else {
        Toast.show('Location permission is required!', context,
            duration: Toast.LENGTH_SHORT);
      }
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings().then((value) {
        _getLocation();
      }).catchError((e) {
        Toast.show('Location permission is required!', context,
            duration: Toast.LENGTH_SHORT);
      });
    }
  }

  Future<void> setLocation(lats, lngs) async {
    final GoogleMapController controller = await _controller.future;
    kGooglePlex = CameraPosition(
      target: LatLng(lats, lngs),
      zoom: 19.151926040649414,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(kGooglePlex));
  }

  void getSharedPref() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      driverName = preferences.getString('delivery_boy_name');
      driverNumber = preferences.getString('delivery_boy_phone');
      imageUrld = Uri.parse(
          '${imageBaseUrl}${preferences.getString('delivery_boy_image')}');
      print('${preferences.getInt('duty')}');
      setState(() {
        status = preferences.getInt('duty');
      });
    });
  }

  void getCurrency() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var currencyUrl = currency;
    var client = http.Client();
    client.get(currencyUrl).then((value) {
      var jsonData = jsonDecode(value.body);
      if (value.statusCode == 200 && jsonData['status'] == "1") {
        print('${jsonData['data'][0]['currency_sign']}');
        preferences.setString(
            'curency', '${jsonData['data'][0]['currency_sign']}');
      }
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scfoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            leading: GestureDetector(
                onTap: () => scfoldKey.currentState.openDrawer(),
                // onTap: () => getSharedPref(),
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.menu)),
            title: status == 1
                ? Text('You\'re Online',
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        .copyWith(fontWeight: FontWeight.w500))
                : Text('You\'re Offline',
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        .copyWith(fontWeight: FontWeight.w500)),
            actions: <Widget>[
              isRun
                  ? CupertinoActivityIndicator(
                      radius: 15,
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: (status == 1) ? kRed : kGreen)),
                  color: (status == 1) ? kRed : kGreen,
                  onPressed: () {
                    if (!isRun) {
                      hitStatusService();
                    }
                  },
                  child: Text(
                    '${status == 1 ? 'Go Offline' : 'Go Online'}',
                    style: Theme.of(context).textTheme.caption.copyWith(
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.7,
                        letterSpacing: 0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Account(driverName, driverNumber, imageUrld),
      body: Stack(
        children: [
          Container(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: kGooglePlex,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
              buildingsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Visibility(
            visible: isRingBell,
            child: Container(
              alignment: Alignment.bottomRight,
              margin: EdgeInsets.only(bottom: 85, right: 35),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ShakeAnimatedWidget(
                  enabled: isRingBell,
                  duration: Duration(milliseconds: 1500),
                  shakeAngle: Rotation.deg(z: 40),
                  curve: Curves.linear,
                  child: Container(
                    height: 30,
                    width: 25,
                    child: Stack(
                      fit: StackFit.loose,
                      children: [
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Icon(Icons.notifications_active)),
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            '${orderCount}',
                            style: TextStyle(
                                color: kGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w400),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: BoomMenu(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        // child: Text('1'),
        onOpen: () {},
        onClose: () => print('DIAL CLOSED'),
        scrollVisible: true,
        overlayColor: Colors.black,
        overlayOpacity: 0.2,
        children: [
          MenuItem(
            title: "Today Order's",
            titleColor: kWhiteColor,
            subtitle: "Tap to view orders",
            subTitleColor: kWhiteColor,
            backgroundColor: Colors.deepOrange,
            onTap: () => Navigator.pushNamed(context, PageRoutes.todayOrder)
                .then((value) {
              hitTestServices();
            }),
          ),
          MenuItem(
            title: "Next Day Order's",
            titleColor: Colors.white,
            subtitle: "Tap to view orders",
            subTitleColor: kWhiteColor,
            backgroundColor: Colors.green,
            onTap: () => Navigator.pushNamed(context, PageRoutes.nextDayOrder)
                .then((value) {
              hitTestServices();
            }),
          ),
        ],
      ),
    );
  }

  void hitTestServices() async {
    preferences = await SharedPreferences.getInstance();
    var client = http.Client();
    var dboy_completed_orderd = today_order_count;
    client.post(dboy_completed_orderd, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}'
    }).then((value) {
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        print('${jsonData.toString()}');
        if (jsonData['status'] == "1") {
          if (jsonData['data'] > 0) {
            orderCount = jsonData['data'];
          }
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        } else {
          if (orderCount > 0) {
            setState(() {
              isRingBell = true;
            });
          } else {
            setState(() {
              isRingBell = false;
            });
          }
        }
      }
    }).catchError((e) {
      if (orderCount > 0) {
        setState(() {
          isRingBell = true;
        });
      } else {
        setState(() {
          isRingBell = false;
        });
      }
      print(e);
    });
  }

  void hitStatusService() async {
    setState(() {
      isRun = true;
    });
    preferences = await SharedPreferences.getInstance();
    dynamic statuss = preferences.getInt('duty');
    var client = http.Client();
    var statusUrl = dboy_status;
    client.post(statusUrl, body: {
      'delivery_boy_id': '${preferences.getInt('delivery_boy_id')}',
      'status': '${statuss == 1 ? 0 : 1}'
    }).then((value) {
      setState(() {
        isRun = false;
      });
      if (value.statusCode == 200 && value.body != null) {
        var jsonData = jsonDecode(value.body);
        DutyOnOff dutyOnOff = DutyOnOff.fromJson(jsonData);
        switch (dutyOnOff.status.toString().trim()) {
          case '0':
            print('0');
            break;
          case '1':
            print('1');
            preferences.setInt('duty', 1);
            setState(() {
              status = preferences.getInt('duty');
            });
            break;
          case '2':
            print('2');
            preferences.setInt('duty', 0);
            setState(() {
              status = preferences.getInt('duty');
            });
            break;
        }
        Toast.show(dutyOnOff.message, context, duration: Toast.LENGTH_SHORT);
      }
    }).catchError((e) {
      print(e);
      setState(() {
        isRun = false;
      });
    });
  }
}

class Account extends StatefulWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  Account(this.driverName, this.driverNumber, this.imageUrld);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String number;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            child: UserDetails(
                widget.driverName, widget.driverNumber, widget.imageUrld),
          ),
          Divider(
            color: kCardBackgroundColor,
            thickness: 8.0,
          ),
          BuildListTile(
              image: 'images/account/ic_menu_home.png',
              text: 'Home',
              onTap: () => Navigator.pop(context)),
          BuildListTile(
              image: 'images/account/ic_menu_tncact.png',
              text: 'Terms & Conditions',
              onTap: () {
                scfoldKey.currentState.openEndDrawer();
                Navigator.pushNamed(context, PageRoutes.tncPage);
              }),
          BuildListTile(
              image: 'images/account/ic_menu_supportact.png',
              text: 'Support',
              onTap: () {
                scfoldKey.currentState.openEndDrawer();
                Navigator.pushNamed(context, PageRoutes.supportPage,
                    arguments: number);
              }),
          BuildListTile(
            image: 'images/account/ic_menu_aboutact.png',
            text: 'About us',
            onTap: () {
              scfoldKey.currentState.openEndDrawer();
              Navigator.pushNamed(context, PageRoutes.aboutUsPage);
            },
          ),
          Column(
            children: <Widget>[
              BuildListTile(
                  image: 'images/account/ic_menu_insight.png',
                  text: 'Order History',
                  onTap: () {
                    scfoldKey.currentState.openEndDrawer();
                    Navigator.pushNamed(context, PageRoutes.insightPage);
                  }),
              LogoutTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BuildListTile(
      image: 'images/account/ic_menu_logoutact.png',
      text: 'Logout',
      onTap: () {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Logging out'),
                content: Text('Are you sure?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('No'),
                    textColor: kMainColor,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: kTransparentColor)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                      child: Text('Yes'),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: kTransparentColor)),
                      textColor: kMainColor,
                      onPressed: () async {
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        pref.clear().then((value) {
                          if (value) {
                            Navigator.pushAndRemoveUntil(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginNavigator();
                            }), (Route<dynamic> route) => false);
                          }
                        });
                      })
                ],
              );
            });
      },
    );
  }
}

class UserDetails extends StatelessWidget {
  final dynamic driverName;
  final dynamic driverNumber;
  final dynamic imageUrld;

  UserDetails(this.driverName, this.driverNumber, this.imageUrld);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 32.0,
                  backgroundImage: NetworkImage('${imageUrld}'),
                ),
                SizedBox(
                  width: 20.0,
                ),
                InkWell(
                  onTap: () {
                    scfoldKey.currentState.openEndDrawer();
                    Navigator.pushNamed(context, PageRoutes.editProfile);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('\n' + '${driverName}',
                          style: Theme.of(context).textTheme.bodyText1),
                      Text('\n' + '${driverNumber}',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2
                              .copyWith(color: Color(0xff9a9a9a))),
                      SizedBox(
                        height: 5.0,
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ));
  }
}
