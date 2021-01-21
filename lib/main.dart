import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    
    home: Wrapper()));
}




class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {



  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
    builder: (context,snapshot){
      if(snapshot.hasError){
        print("Error");
      }
      if(snapshot.connectionState==ConnectionState.done){




        return getToken();
      }

      if(snapshot.connectionState==ConnectionState.waiting){
        return CircularProgressIndicator();
      }
      return Scaffold(body:Center(child: CircularProgressIndicator(),));
    },      
    );
  }
}




class getToken extends StatefulWidget {
  @override
   getTokenState createState() =>  getTokenState();
}

class  getTokenState extends State <getToken> {



@override
void initState() { 
  super.initState();
  getMessage();
  
}


String _message = '';

  FirebaseMessaging messaging = FirebaseMessaging.instance;

void getMessage()async{

//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//   alert: true, // Required to display a heads up notification
//   badge: true,
//   sound: true,
// );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');

  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
});

  }


FirebaseAuth auth=FirebaseAuth.instance;

TextEditingController name=TextEditingController();



  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context,snap){
          if(snap.data==null){
            return Scaffold(
              body:Center(child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                                      child: TextField(
                      controller:name,
                      decoration:InputDecoration(
                        labelText:"Enter Name",
                      )
                    ),
                  ),
                  RaisedButton(onPressed: ()async{
                    
                   await auth.signInAnonymously().then((value) async{
FirebaseFirestore.instance
    .collection('users')
    .doc(value.user.uid).set({
      "name":name.text.trim(),
      "token":"",
      "uid":value.user.uid
    });

                   });


                  },
                  child: Text("Login"),
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),)
            );
          }

          if(snap.hasData){
            return MyApp();
          }
          return Scaffold(
            body: CircularProgressIndicator(),
          );
        });
  }
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  String user;
  Future<void> saveTokenToDatabase() async {


     String token = await FirebaseMessaging.instance.getToken();
 
   user = FirebaseAuth.instance.currentUser.uid;

  await FirebaseFirestore.instance
    .collection('users')
    .doc(user)
    .update({
      'token': token,
    });




}



@override
  void initState() {

    super.initState();
    saveTokenToDatabase();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
              child: Column(children: [
          
          Text("Hello"),

          Padding(
            padding: EdgeInsets.all(20),
            child: Text("Send Notification To:")),
        
        

  Expanded(
        child: FutureBuilder(
        future: FirebaseFirestore.instance.collection("users").where("uid",isNotEqualTo: FirebaseAuth.instance.currentUser.uid).get(),
        builder: (context,AsyncSnapshot<QuerySnapshot> snapshot){

        
        return snapshot.hasData?ListView.builder(itemBuilder: (context,index){
          return Card(child: ListTile(
            title: Text(snapshot.data.docs[index]["name"]),
            trailing: RaisedButton(onPressed: ()async{
         var res = await http.post("https://limitless-brook-04099.herokuapp.com/api/",
              headers: {
              
          'Content-Type': 'Application/json'
              },
              body: jsonEncode(<String, String>{
      'token':'${snapshot.data.docs[index]["token"]}',
    }),
              );

              print(res);
            },
            child:Text("Send Notification")
            ),
          ),); 
        },
        itemCount: snapshot.data.docs.length,
        ):Center(child: CircularProgressIndicator());
    }),
  ),
  RaisedButton(onPressed: (){
          FirebaseAuth.instance.signOut();
        },
        child: Text("Log Out"),
        ),

        ],
     
        ),
      ),
    );
  }
}