import 'package:flutter/material.dart';
import 'home_page.dart';
import 'instance_list_page.dart';
import 'myvars.dart';

class BottomPage extends StatelessWidget {
  const BottomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    Icons.home,
                    color: bottomIconColor['home'],
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => HomePage()));
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text("Home"),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    Icons.edit_note,
                    color: bottomIconColor['instance'],
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => InstanceListPage()));
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text("Management"),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: bottomIconColor['setting'],
                  ),
                  onPressed: () {},
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text("Settings"),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: bottomIconColor['account'],
                  ),
                  onPressed: () {},
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text("Account"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
