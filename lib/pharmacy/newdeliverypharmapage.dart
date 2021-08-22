import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:driver/Components/bottom_bar.dart';
import 'package:driver/Routes/routes.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/Themes/style.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:driver/beanmodel/todayrestorder.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:toast/toast.dart';

class NewDeliveryPharmaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NewDeliveryPharmaBody();
  }
}

class NewDeliveryPharmaBody extends StatefulWidget {
  @override
  _NewDeliveryPharmaBodyState createState() => _NewDeliveryPharmaBodyState();
}

// Starting point latitude
double _originLatitude = 6.5212402;
// Starting point longitude
double _originLongitude = 3.3679965;
// Destination latitude
double _destLatitude = 6.849660;
// Destination Longitude
double _destLongitude = 3.648190;
// Markers to show points on the map
Map<MarkerId, Marker> markers = {};

class _NewDeliveryPharmaBodyState extends State<NewDeliveryPharmaBody> {
  dynamic cart_id = '';
  dynamic vendorName = '';
  dynamic vendorAddress = '';
  dynamic vendorDistance = '';
  dynamic userName = '';
  dynamic userAddress = '';
  dynamic userphone;
  dynamic vendorlat;
  dynamic vendorlng;
  dynamic dlat;
  dynamic dlng;
  dynamic userlat;
  dynamic userlng;
  dynamic remprice;
  dynamic paymentstatus;
  dynamic paymentMethod;
  List<TodayRestaurantOrderDetails> orderDeatisSub;
  List<AddonList> addons;
  dynamic distance;

  // Google Maps controller
  Completer<GoogleMapController> _controller = Completer();
  // Configure map position and zoom
  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(_originLatitude, _originLongitude),
    zoom: 9.4746,
  );

  @override
  void initState() {
    /// add origin marker origin marker
    _addMarker(
      LatLng(_originLatitude, _originLongitude),
      "origin",
      BitmapDescriptor.defaultMarker,
    );

    // Add destination marker
    _addMarker(
      LatLng(_destLatitude, _destLongitude),
      "destination",
      BitmapDescriptor.defaultMarkerWithHue(90),
    );
    super.initState();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final ProgressDialog pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: true);
    pr.style(
        message: 'Loading please wait...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    final Map<String, Object> dataObject =
        ModalRoute.of(context).settings.arguments;
    setState(() {
      cart_id = dataObject['cart_id'];
      vendorName = dataObject['vendorName'];
      vendorAddress = dataObject['vendorAddress'];
      userName = dataObject['userName'];
      userAddress = dataObject['userAddress'];
      userphone = dataObject['userphone'];
      vendorlat = dataObject['vendorlat'];
      _originLatitude = double.parse(vendorlat);
      vendorlng = dataObject['vendorlng'];
      _originLongitude = double.parse(vendorlng);
      dlat = dataObject['dlat'];
      dlng = dataObject['dlng'];
      userlat = dataObject['userlat'];
      _destLatitude = double.parse(userlat);
      userlng = dataObject['userlng'];
      _destLongitude = double.parse(userlng);
      remprice = dataObject['remprice'];
      paymentstatus = dataObject['paymentstatus'];
      paymentMethod = dataObject['paymentMethod'];
      orderDeatisSub = dataObject['itemDetails'] as List;
      addons = dataObject['addons'] as List;
      distance = calculateDistance(
              double.parse(vendorlat), double.parse(vendorlng), dlat, dlng)
          .toStringAsFixed(2);
      _kGooglePlex = CameraPosition(
        target: LatLng(_originLatitude, _originLongitude),
        zoom: 12.4746,
      );
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            automaticallyImplyLeading: true,
            title: Text('New Order - #${cart_id}',
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              myLocationEnabled: true,
              tiltGesturesEnabled: true,
              compassEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              markers: Set<Marker>.of(markers.values),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.3),
                      child: Image.asset(
                        'images/vegetables_fruitsact.png',
                        height: 42.3,
                        width: 33.7,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          '${vendorName}',
                          style: orderMapAppBarTextStyle.copyWith(
                              letterSpacing: 0.07),
                        ),
                        subtitle: Row(
                          children: <Widget>[
                            Text(
                              '${distance} km',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  .copyWith(
                                      fontSize: 11.7,
                                      letterSpacing: 0.06,
                                      color: kMainColor,
                                      fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '(20 min)',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  .copyWith(
                                      fontSize: 11.7,
                                      letterSpacing: 0.06,
                                      color: Color(0xffc1c1c1)),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Divider(
                  color: kCardBackgroundColor,
                  thickness: 1.0,
                ),
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                          left: 36.0, bottom: 6.0, top: 6.0, right: 20.0),
                      child: ImageIcon(
                        AssetImage('images/custom/ic_pickup_pointact.png'),
                        size: 13.3,
                        color: kMainColor,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${vendorName}',
                          style: orderMapAppBarTextStyle.copyWith(
                              fontSize: 10.0, letterSpacing: 0.05),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          '${vendorAddress}',
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(fontSize: 10.0, letterSpacing: 0.05),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 5.0,
                ),
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                          left: 36.0, bottom: 12.0, top: 12.0, right: 20.0),
                      child: ImageIcon(
                        AssetImage('images/custom/ic_droppointact.png'),
                        size: 13.3,
                        color: kMainColor,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${userName}',
                          style: orderMapAppBarTextStyle.copyWith(
                              fontSize: 10.0, letterSpacing: 0.05),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          '${userAddress}',
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(fontSize: 10.0, letterSpacing: 0.05),
                        ),
                      ],
                    ),
                  ],
                ),
                BottomBar(
                    text: "Accept Delivery",
                    onTap: () {
                      pr.show();
                      hitServiceRest(cart_id, pr, context);
                    }),
              ],
            ),
          )
        ],
      ),
    );
  }

  void hitServiceRest(cartid, ProgressDialog pr, context) async {
    var url = pharmacy_delivery_accepted_by_dboy;
    var client = http.Client();
    client.post(url, body: {'cart_id': '${cartid}'}).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);
        if (jsonData['status'] == "1") {
          pr.hide();
          Toast.show('Order Accepted', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
          Navigator.popAndPushNamed(context, PageRoutes.pharmaacceptpage,
              arguments: {
                "cart_id": cart_id,
                "vendorName": vendorName,
                "vendorAddress": vendorAddress,
                "vendorlat": vendorlat,
                "vendorlng": vendorlng,
                "dlat": dlat,
                "dlng": dlng,
                "userlat": userlat,
                "userlng": userlng,
                "userName": userName,
                "userAddress": userAddress,
                "userphone": userphone,
                "itemDetails": orderDeatisSub,
                "remprice": remprice,
                "paymentstatus": paymentstatus,
                "paymentMethod": paymentMethod,
                "ui_type": "2",
                "addons": addons
              });
        } else {
          pr.hide();
          Toast.show('Order Not Accepted', context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        }
      }
    }).catchError((e) {
      pr.hide();
      print(e);
    });
  }
}

// This method will add markers to the map based on the LatLng position
_addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
  MarkerId markerId = MarkerId(id);
  Marker marker =
      Marker(markerId: markerId, icon: descriptor, position: position);
  markers[markerId] = marker;
}
