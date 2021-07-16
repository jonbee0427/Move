import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:move/data.dart';
import 'package:move/home_page.dart';
import 'package:move/front/game.dart';
import 'package:move/trex/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:move/front/select.dart';
import 'game.dart';

class TRexGameWrapper extends StatefulWidget {

  final List<BluetoothService>? bluetoothServices;
  TRexGameWrapper({this.bluetoothServices});

  @override
  _TRexGameWrapperState createState() => _TRexGameWrapperState();
}

class _TRexGameWrapperState extends State<TRexGameWrapper> {
  /*--------bluetooth-------*/
  final StreamController<int> _streamController = StreamController<int>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();
  bool splashGone = false;
  TRexGame ? game;

  int score = 0;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    Flame.images.loadAll(["sprite.png"]).then(
          (image) => {
        setState(() {
          game = TRexGame(spriteImage: image[0]);
        })
      },
    );
  }

  @override
  void dispose(){
    _streamController.close();
    super.dispose();
  }

  void _gesture() {
    for (BluetoothService service in widget.bluetoothServices!) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          characteristic.value.listen((value) {
            readValues[characteristic.uuid] = value;
          });
          characteristic.setNotifyValue(true);
        }
        if (characteristic.properties.read &&
            characteristic.properties.notify) {
          setnum(characteristic);
        }
      }
    }
  }

  Future<void> setnum(characteristic) async {
    var sub = characteristic.value.listen((value) {
      if (mounted) { //Exception
        setState(() {
          readValues[characteristic.uuid] = value;
          gesture = value.toString();
          gesture_num = int.parse(gesture[1]);
        });
      }
    });

    await characteristic.read();
    sub.cancel();
  }

  Widget scoreBox(BuildContext buildContext, TRexGame game) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
              margin: EdgeInsets.only(top: 25, right: 5),
              width: 100,
              height: 30,
              child: Center(
                child: Text('Score : $score', style: TextStyle(color: Colors.black, fontSize: 16, decoration: TextDecoration.none)),
              )
          )
        ]
    );
  }

  Widget exitBox(BuildContext buildContext, TRexGame game) {
    return Container(
      margin: EdgeInsets.only(top: 17),
      width: 100,
      height: 100,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Select(bluetoothServices: widget.bluetoothServices)));
                },
                child: Image.asset('dinoExit.png', height: 50,),
              ),
            ),
          ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _gesture();
    game!.onAction(gesture_num);
    score = game!.returnScore();

    if (game == null) {
      return const Center(
        child: Text("Loading"),
      );
    }
    return Container(
      constraints: const BoxConstraints.expand(),
      child: GameWidget(
        game: game!,
        overlayBuilderMap: {
          'Score' : scoreBox,
          'Exit' : exitBox
        },
        initialActiveOverlays: ['Score', 'Exit'],
      ),
    );
  }

}