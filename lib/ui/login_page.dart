import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hello_me/data/auth_repository.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  String _confirmedPassword = "";
  String _email = "";
  String _password = "";

  Widget confirmPasswordTitle(context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
          padding: EdgeInsets.all(10),
          child: const Text("Please confirm your password below:")),
      const Divider(),
    ]);
  }

  Widget confirmPasswordField(context) {
    return Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: TextFormField(
          validator: (value) =>
              _password != _confirmedPassword ? "Password must match" : null,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Confirmed password',
          ),
          onChanged: (text) => _confirmedPassword = text,
        ));
  }

  Widget confirmPasswordButton(context, GlobalKey<FormState> _formKey) {
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
          AuthRepository auth = AuthRepository.instance();

          if (_formKey.currentState!.validate()) {
            await auth.signUp(_email, _password);
            await auth.signIn(_email, _password);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
        child: const Text('Confirm'),
      ),
    );
  }

  Widget confirmationForm(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Form(
        key: _formKey,
        child: Column(children: [
          confirmPasswordTitle(context),
          confirmPasswordField(context),
          confirmPasswordButton(context, _formKey),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Container(
        child: Consumer<AuthRepository>(
            builder: (context, auth, _) => Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        child: const Text(
                            "Welcome to Startup Names Generator, please log in below"),
                      ),
                      Container(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Email',
                            ),
                            onChanged: (text) => _email = text,
                          )),
                      Container(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 20),
                          child: TextFormField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                            ),
                            onChanged: (text) => _password = text,
                          )),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 30, right: 30, top: 20),
                        child: ElevatedButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18.0)))),
                          onPressed: auth.status == Status.Authenticating
                              ? null
                              : () async {
                                  bool succeeded =
                                      await auth.signIn(_email, _password);
                                  if (!succeeded) {
                                    // Show snackbar
                                    const snackBar = SnackBar(
                                      content: Text(
                                          'There was an error logging into the app'),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                  } else {
                                    // Navigate back
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: const Text('Log in'),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                            const EdgeInsets.only(left: 30, right: 30, top: 20),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0))),
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.blue),
                          ),
                          onPressed: auth.status == Status.Authenticating
                              ? null
                              : () async {
                                  showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      builder: (context) {
                                        return confirmationForm(context);
                                      });
                                  // bool succeeded =
                                  //     await auth.signIn(_email, _password);
                                  // if (!succeeded) {
                                  //   // Show snackbar
                                  //   const snackBar = SnackBar(
                                  //     content: Text(
                                  //         'There was an error logging into the app'),
                                  //   );
                                  //   ScaffoldMessenger.of(context)
                                  //       .showSnackBar(snackBar);
                                  // } else {
                                  //   // Navigate back
                                  //   Navigator.of(context).pop();
                                  // }
                                },
                          child: const Text('New user? Click here to sign up'),
                        ),
                      ),
                    ],
                  ),
                )));
  }
}
