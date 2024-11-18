import 'package:flutter/material.dart';

class CustomDialog {
  static void showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            height: 120,
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green, // Set the background color to green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), // Set the border radius
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white), // Set the text color to white
                ),
              ),
            )
          ],
        );
      },
    );
  }

  static void showConfirmDialog(BuildContext context, String title, String content, Function onYesPressed, {Function? onNoPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            height: 120,
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onNoPressed?.call() ?? () {};
                  },
                  child: const Text(
                    'NO',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onYesPressed();
                  },
                  child: const Text(
                    'YES',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}