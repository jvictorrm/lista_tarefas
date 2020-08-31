import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _taskController = TextEditingController();

  List _taskList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();
    _readDatabase().then((data) {
      setState(() {
        _taskList = json.decode(data);
      });
    });
  }

  void _addTask() {
    setState(() {
      if (_taskController.text.trim().isEmpty) {
        return;
      }

      Map<String, dynamic> newTaskMap = Map();
      newTaskMap["title"] = _taskController.text;
      newTaskMap["is_checked"] = false;

      _taskList.add(newTaskMap);

      _taskController.text = "";

      _saveDatabase();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _taskList.sort((a , b) {
        if (a["is_checked"] && !b["is_checked"]) return 1;
        else if (!a["is_checked"] && b["is_checked"]) return -1;
        else return 0;
      });

      _saveDatabase();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        title: Text("Lista de Tarefas"),
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueGrey)),
                  ),
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  textColor: Colors.white,
                  color: Colors.blueGrey,
                  child: Text(
                    "+",
                    style: TextStyle(fontSize: 40.0),
                  ),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh:_refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _taskList.length,
                  itemBuilder: _buildItem),
            ),
          )
        ],
      ),
    );
  }

  Future<File> _getFileDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveDatabase() async {
    String data = json.encode(_taskList);
    final file = await _getFileDatabase();
    return file.writeAsString(data);
  }

  Future<String> _readDatabase() async {
    try {
      final file = await _getFileDatabase();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget _buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_taskList[index]);
            _lastRemovedIndex = index;
            _taskList.removeAt(index);

            _saveDatabase();

            final snackBar = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
              action: SnackBarAction(label: "Desfazer", onPressed: () {
                setState(() {
                  _taskList.insert(_lastRemovedIndex, _lastRemoved);
                  _saveDatabase();
                });
              },),
              duration: Duration(seconds: 2),
            );

            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snackBar);
          });
        },
        child: CheckboxListTile(
          title: Text(_taskList[index]["title"]),
          value: _taskList[index]["is_checked"],
          activeColor: Colors.green,
          secondary: _taskList[index]["is_checked"]
              ? CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ))
              : CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(
                    Icons.error,
                    color: Colors.white,
                  )),
          onChanged: (isChecked) {
            setState(() {
              _taskList[index]["is_checked"] = isChecked;
              _saveDatabase();
            });
          },
        )
    );
  }
}
