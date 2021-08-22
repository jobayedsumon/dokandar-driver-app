import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/Auth/login_navigator.dart';
import 'package:driver/Locale/locales.dart';
import 'package:driver/Themes/colors.dart';
import 'package:driver/baseurl/baseurl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

class PhoneNumber_New extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhoneNumber(),
    );
  }
}

class PhoneNumber extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PhoneNumberState();
  }
}

class PhoneNumberState extends State<PhoneNumber> {
  static const String id = 'phone_number';
  final TextEditingController _controller = TextEditingController();
  String isoCode = '+880';
  var scafoldKey = GlobalKey<ScaffoldState>();

  var showDialogBox = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scafoldKey,
      body: WillPopScope(
        onWillPop: () {
          return _handlePopBack();
        },
        child: SingleChildScrollView(
          child: Container(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Positioned(
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: 50,
                          ),
                          Image.asset(
                            "images/logos/logo_delivery.png",
                            height: 130.0,
                            width: 99.7,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 5),
                            child: Text(
                              '${appname}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: kMainTextColor,
                                  fontSize: 30.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          //text on page
                          Text(AppLocalizations.of(context).bodyText1,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyText1),
                          Text(
                            AppLocalizations.of(context).bodyText2,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 52.0,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      "images/logos/Delivery.gif",
                      width: MediaQuery.of(context).size.width, //footer image
                    ),
                  ),
                  PositionedDirectional(
                      bottom: 0.0,
                      width: MediaQuery.of(context).size.width,
                      height: 52,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CountryCodePicker(
                              onChanged: (value) {
                                isoCode = value.code;
                              },
                              builder: (value) => buildButton(value),
                              initialSelection: '+880',
                              textStyle: Theme.of(context).textTheme.caption,
                              showFlag: false,
                              showFlagDialog: true,
                              favorite: ['+880', 'BD'],
                            ),
                            SizedBox(
                              width: 5.0,
                            ),
                            //takes phone number as input
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                child: TextFormField(
                                  controller: _controller,
                                  keyboardType: TextInputType.number,
                                  readOnly: false,
                                  textAlign: TextAlign.left,
                                  decoration: InputDecoration(
                                    hintText:
                                        AppLocalizations.of(context).mobileText,
                                    border: InputBorder.none,
                                    counter: Offstage(),
                                    contentPadding: EdgeInsets.only(left: 30),
                                    hintStyle: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: kHintColor,
                                        fontSize: 16),
                                  ),
                                  maxLength: 10,
                                ),
                              ),
                            ),
                            RaisedButton(
                              child: Text(
                                AppLocalizations.of(context).continueText,
                                style: TextStyle(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.w400),
                              ),
                              color: kMainColor,
                              highlightColor: kMainColor,
                              focusColor: kMainColor,
                              splashColor: kMainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              onPressed: () {
                                SystemChannels.textInput
                                    .invokeMethod('TextInput.hide');
                                setState(() {
                                  showDialogBox = true;
                                });
                                if (_controller.text.length < 10) {
                                  setState(() {
                                    showDialogBox = false;
                                  });
                                  Toast.show(
                                      "Enter valid mobile number!", context,
                                      gravity: Toast.BOTTOM);
                                } else {
                                  hitService(
                                      isoCode, _controller.text, context);
                                }
                              },
                            ),
                          ],
                        ),
                      )),
                  Positioned.fill(
                      child: Visibility(
                    visible: showDialogBox,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height - 100,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 120,
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Material(
                            elevation: 5,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.hardEdge,
                            child: Container(
                              color: kWhiteColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  CircularProgressIndicator(),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text(
                                    'Loading please wait!....',
                                    style: TextStyle(
                                        color: kMainTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              )),
        ),
      ),
    );
  }

  void hitService(
      String isoCode, String phoneNumber, BuildContext context) async {
    var url = delievery_boy_phone_verify;
    var client = http.Client();
    client.post(url, body: {'phone': isoCode + phoneNumber}).then(
        (response) async {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        Toast.show(jsonData['message'], context, gravity: Toast.BOTTOM);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("delivery_boy_phone", isoCode + phoneNumber);
        setState(() {
          showDialogBox = false;
        });
        if (jsonData['status'] == "1") {
          Navigator.pushNamed(context, LoginRoutes.verification);
        } else {
          showAlertDialog(context);
        }
      } else {
        setState(() {
          showDialogBox = false;
        });
      }
    }).catchError((e) {
      print(e);
      setState(() {
        showDialogBox = false;
      });
    });
  }

  showAlertDialog(BuildContext context) {
    Widget remindButton = FlatButton(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text("Notice"),
      content: Text(
          "Your number is not verified yet. Please contact with customer care."),
      actions: [
        remindButton,
      ],
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  buildButton(CountryCode isoCode) {
    return Row(
      children: <Widget>[
        Text(
          '$isoCode',
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }

  Future<bool> _handlePopBack() async {
    bool isVal = false;
    if (showDialogBox) {
      setState(() {
        showDialogBox = false;
      });
    } else {
      isVal = true;
    }
    return isVal;
  }
}
