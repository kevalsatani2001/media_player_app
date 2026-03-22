import 'package:flutter/material.dart';

class DialogHelper {
  static BuildContext? _dialogContext;

  // à«§. àªàª¡ àª²à«‹àª¡àª¿àª‚àª— àª¡àª¾àª¯àª²à«‹àª— àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
  static void showAdLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _dialogContext = ctx; // àª•à«‹àª¨à«àªŸà«‡àª•à«àª¸à«àªŸ àª¸à«àªŸà«‹àª° àª•àª°à«‹ àªœà«‡àª¥à«€ àª¬àª¹àª¾àª°àª¥à«€ àª¬àª‚àª§ àª•àª°à«€ àª¶àª•àª¾àª¯
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 20),
                Text(
                  "Loading Ad...",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  "Please wait a moment",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // à«¨. àª¡àª¾àª¯àª²à«‹àª— àª¬àª‚àª§ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡
  static void hideDialog(BuildContext context) {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop();
      _dialogContext = null;
    }
  }
}