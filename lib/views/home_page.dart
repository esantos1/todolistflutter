import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todolist/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List todoList = [];
  TextEditingController todoController = TextEditingController();
  late int indexLastRemoved;
  late Map<String, dynamic> lastRemoved;

  @override
  void initState() {
    super.initState();

    readData().then((value) {
      if (value != null) {
        List decodedList = json.decode(value);
        setState(() =>
            todoList = decodedList.whereType<Map<String, dynamic>>().toList());
      }
    });
  }

  Future<String?> readData() async {
    try {
      final file = await openFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<File> saveData() async {
    String data =
        json.encode(todoList.where((element) => element != null).toList());
    final file = await openFile();

    return file.writeAsString(data);
  }

  Future<File> openFile() async {
    final appPath = await getApplicationDocumentsDirectory();

    return File("${appPath.path}/todoList.json");
  }

  Future<void> refreshList() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      todoList.sort((a, b) {
        if (a == null || b == null) {
          return 0;
        }
        if (a['done'] && !b['done']) return 1;
        if (!a['done'] && b['done']) return -1;
        return 0;
      });

      saveData();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          appBar: AppBar(title: Text('Todo List')),
          body: Builder(builder: (context) => buildList()),
          floatingActionButton: FloatingActionButton(
            onPressed: buildForm,
            child: Icon(Icons.add),
          ),
        ),
      );

  void buildForm() {
    Future<Map<String, dynamic>?> task = showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) => AlertDialog(
        title: Text('Adicionar tarefa'),
        content: TextField(
          controller: todoController,
          maxLength: 40,
          decoration: InputDecoration(labelText: 'Nova tarefa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(onPressed: addClicked, child: Text('Adicionar')),
        ],
      ),
    );

    task.then((value) {
      setState(() {
        if (value != null) {
          todoList.add(value);
        }

        todoController.clear();

        saveData();
        refreshList();
      });
    });
  }

  void addClicked() {
    if (todoController.text.isEmpty) {
      showCustomSnackBar(
        context: context,
        title: 'Insira uma tarefa para adicionar',
        snackBarActionLabel: 'Ok',
        onSnackBarActionClicked: () =>
            ScaffoldMessenger.of(context).removeCurrentSnackBar(),
      );
    } else {
      Map<String, dynamic> newTask = {
        'title': todoController.text,
        'done': false,
      };

      Navigator.pop(context, newTask);
    }
  }

  Widget buildList() => RefreshIndicator(
        onRefresh: refreshList,
        child: ListView.builder(
          padding: EdgeInsets.all(defaultPadding),
          itemCount: todoList.length,
          itemBuilder: (context, index) {
            final item = todoList[index];
            debugPrint(item.toString());

            return buildTask(context, index, item);
          },
        ),
      );

  Widget buildTask(BuildContext context, int index, dynamic item) =>
      Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          alignment: Alignment(0.85, 0.0),
          child: Icon(Icons.delete_sweep, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        child: buildItemWidget(item),
        onDismissed: (dismissed) => dismissItem(dismissed, item, index),
      );

  Widget buildItemWidget(dynamic item) {
    if (item == null) {
      return Container();
    }

    return CheckboxListTile(
      value: item['done'],
      secondary: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          item['done'] ? Icons.check : Icons.error,
          color: Colors.white,
        ),
      ),
      title: Text(item['title']),
      onChanged: (value) => setState(() {
        item['done'] = value;

        saveData();
        refreshList();
      }),
    );
  }

  void dismissItem(DismissDirection dismissed, dynamic item, int index) {
    setState(() {
      lastRemoved = Map.from(item);
      indexLastRemoved = index;

      todoList.removeAt(index);

      saveData();

      showCustomSnackBar(
        context: context,
        title: 'A tarefa "${lastRemoved['title']}" foi excluída',
        snackBarActionLabel: 'Desfazer',
        onSnackBarActionClicked: () => setState(() {
          todoList.insert(indexLastRemoved, lastRemoved);

          saveData();
        }),
      );

      refreshList();
    });
  }
}
