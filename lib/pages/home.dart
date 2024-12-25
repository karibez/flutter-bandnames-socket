import 'dart:io';

import 'package:band_name/models/band.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:band_name/services/socket_service.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
          title: const Align(
              alignment: Alignment.center,
              child: Text('BandNames',
                  style: TextStyle(color: Color.fromARGB(221, 232, 231, 236)))),
          backgroundColor: const Color.fromARGB(255, 162, 163, 240),
          elevation: 1,
          actions: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 10),
              child: (socketService.serverStatus == ServerStatus.Online)
                  ? Icon(Icons.check_circle,
                      color: const Color.fromARGB(255, 90, 64, 241))
                  : const Icon(Icons.offline_bolt, color: Colors.red),
            ),
          ]),
      body: Column(children: [

        _showGraph(bands),

        Expanded(
          child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i])),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          elevation: 1, onPressed: addNewBand, child: const Icon(Icons.add)),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
          padding: const EdgeInsets.only(left: 10.0),
          color: Colors.red,
          child: const Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Delete band', style: TextStyle(color: Colors.white)))),
      child: ListTile(
        
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 90, 64, 241),
          child: Text(band.name.substring(0, 2),
              style: const TextStyle(
                  fontSize: 15, color: Color.fromARGB(255, 162, 163, 240))),
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
        onTap: () => socketService.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();
    if (!Platform.isAndroid) {
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: const Text('New band name:'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                  elevation: 5,
                  textColor: Colors.blue,
                  onPressed: () => addBandToList(textController.text),
                  child: const Text('Add'))
            ]),
      );
    }

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('New band name:'),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () => addBandToList(textController.text)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context),
          ),
        ],  
      ),
    );
  }

  void addBandToList(String name) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    print(name);
    if (name.length > 1) {
      //Podemos agregar
      socketService.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }
}

Widget _showGraph(List<Band> bands) {
  Map<String, double> dataMap = {
  };

  bands.forEach(( band ){
         dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
     });

  return Container(
    margin: const EdgeInsets.only(top:10),
    width: double.infinity,
    height: 150,
    child: PieChart(
      chartType: ChartType.ring,
      dataMap: dataMap));
}
