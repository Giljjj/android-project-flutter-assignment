import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/data/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

import 'RandomWords.dart';

class Sheet extends StatefulWidget {
  const Sheet({Key? key}) : super(key: key);

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet> {
  final snappingSheetController = SnappingSheetController();
  StreamController<Widget> profilePicStream = StreamController.broadcast();
  StreamController<num> blurStream = StreamController.broadcast();
  final randomWords = const RandomWords(key: GlobalObjectKey('random words'));

  void loadImage(StreamController streamController, outerRef) async {
    var _auth = AuthRepository.instance();
    String userId = _auth.user!.uid;
    final destination = 'files/$userId';
    Widget result = Container(padding: const EdgeInsets.all(25));

    try {
      var ref = outerRef;
      ref ??= FirebaseStorage.instance.ref(destination).child('profile/');
      var urlFuture = await ref.getDownloadURL();
      var url = urlFuture.toString();

      if (url.isNotEmpty) {
        result = Image.network(
          url,
          height: 50,
          width: 50,
        );
      } else {
        result = Container(padding: const EdgeInsets.all(25));
      }
    } catch (e) {
      result = Container(padding: const EdgeInsets.all(25));
    }

    streamController.add(result);
  }

  Widget changeAvatarButton(
      context, StreamController<Widget> streamController) {
    return Container(
      // width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
      child: ElevatedButton(
        style: ButtonStyle(
          // shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          //     RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(18.0))),
          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
        ),
        onPressed: () async {
          final storage = FirebaseStorage.instance;

          File? _photo;
          final _picker = ImagePicker();

          final pickedFile =
              await _picker.pickImage(source: ImageSource.gallery);

          if (pickedFile != null) {
            _photo = File(pickedFile.path);
            if (_photo == null) return;
            var _auth = AuthRepository.instance();
            String userId = _auth.user!.uid;
            final destination = 'files/$userId';

            try {
              final ref =
                  FirebaseStorage.instance.ref(destination).child('profile/');
              streamController.add(Center(child: CircularProgressIndicator()));
              await ref.putFile(_photo);
              loadImage(streamController, ref);
              // _auth.profileChanged();
              // Notify
            } catch (e) {}
          } else {
            const snackBar = SnackBar(
              content: Text('No image selected'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        child: const Text('Change avatar'),
      ),
    );
  }

  Widget userInfo(context, AuthRepository auth, streamController) {
    return Column(children: [
      Text(auth.user?.email ?? "No email"),
      changeAvatarButton(context, streamController),
    ]);
  }

  Widget userProfile(context, AuthRepository auth) {
    loadImage(profilePicStream, null);

    return Container(
      child: Row(
        children: [
          // FutureBuilder<Widget>(
          //   future: profilePicture(auth),
          //   builder: (context, snapshot) {
          //     if (snapshot.hasData && snapshot.data != null) {
          //       return snapshot.data!;
          //     } else {
          //       return Container(padding: EdgeInsets.all(25));
          //     }
          //   },
          // ),

          StreamBuilder<Widget>(
              stream: profilePicStream.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return snapshot.data!;
                } else {
                  return Container(padding: EdgeInsets.all(25));
                }
              }),

          // profilePicture(auth),
          userInfo(context, auth, profilePicStream),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  SnappingSheetContent sheetContent(context, AuthRepository auth) {
    return SnappingSheetContent(
        draggable: true,
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [userProfile(context, auth)],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
          color: Colors.white,
        ));
  }

  Widget welcomeRow(AuthRepository auth) {
    return InkWell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              padding: EdgeInsets.all(16),
              child: Text("Welcome back, ${auth.user?.email}")),
          Container(
              padding: EdgeInsets.all(16),
              child: const Icon(
                Icons.expand_less,
                color: Colors.black,
              )),
          // )),
        ],
      ),
      onTap: () {
        if (snappingSheetController.isAttached) {
          if (snappingSheetController.currentPosition >= 150) {
            // snappingSheetController.setSnappingSheetPosition(75 / 2);
            snappingSheetController.snapToPosition(
                const SnappingPosition.pixels(positionPixels: 75 / 2));
          } else {
            // snappingSheetController.setSnappingSheetPosition(150);
            snappingSheetController.snapToPosition(
                const SnappingPosition.pixels(positionPixels: 150));
          }
        }
      },
    );
  }

  Widget grabbingWidget(AuthRepository auth) {
    return Container(
      child: welcomeRow(auth),
      color: Colors.grey,
    );
  }

  List<SnappingPosition> snappingPositions() {
    return [
      const SnappingPosition.factor(
        positionFactor: 0.0,
        snappingCurve: Curves.easeOutExpo,
        snappingDuration: Duration(seconds: 1),
        grabbingContentOffset: GrabbingContentOffset.top,
      ),
      const SnappingPosition.pixels(
        positionPixels: 150,
        snappingCurve: Curves.elasticOut,
        snappingDuration: Duration(milliseconds: 1750),
      ),
      const SnappingPosition.factor(
        positionFactor: 0.75,
        snappingCurve: Curves.bounceOut,
        snappingDuration: Duration(seconds: 1),
        grabbingContentOffset: GrabbingContentOffset.bottom,
      ),
    ];
  }

  Widget snappingSheetContent() {
    return StreamBuilder(
        stream: blurStream.stream,
        builder: (context, AsyncSnapshot<num> snapshot) {
          // if (snapshot.hasData && snapshot.data != null) {
          bool ignoring = true;
          if (snappingSheetController.isAttached) {
            ignoring = snappingSheetController.currentPosition <= 38.0;
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              randomWords,
              IgnorePointer(
                  ignoring: (ignoring),
                  child: InkWell(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 10.0 * (snapshot.data ?? 0),
                        sigmaY: 10.0 * (snapshot.data ?? 0),
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                    onTap: () {
                      snappingSheetController.snapToPosition(
                          const SnappingPosition.pixels(
                              positionPixels: 75 / 2));
                    },
                  ))
            ],
          );
          // }
        });
  }

  @override
  void initState() {
    super.initState();
    // profilePicStream = StreamController();
    // profilePicStream.
    // blurStream = StreamController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(builder: (context, auth, _) {
      if (auth.isAuthenticated) {
        return SnappingSheet(
          lockOverflowDrag: true,
          controller: snappingSheetController,
          onSheetMoved: (sheetPosition) {
            blurStream.add(sheetPosition.relativeToSheetHeight - 0.07);
          },
          child: snappingSheetContent(),
          grabbingHeight: 75,
          grabbing: grabbingWidget(auth),
          sheetBelow: sheetContent(context, auth),
          snappingPositions: snappingPositions(),
        );
      }
      return randomWords;
    });
  }

  @override
  void dispose() {
    super.dispose();
    profilePicStream.close();
  }
}
