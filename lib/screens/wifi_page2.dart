import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import '../services/wifi_p2p_manager.dart';
import 'dart:async';
import 'package:filesystem_picker/filesystem_picker.dart';

class WifiPage2 extends StatefulWidget {
  const WifiPage2({super.key});

  @override
  State<WifiPage2> createState() => _WifiPage2State();
}

class _WifiPage2State extends State<WifiPage2> with WidgetsBindingObserver,AutomaticKeepAliveClientMixin{
  final TextEditingController msgText = TextEditingController();
  //final WifiP2PManager _wifiP2PManager = WifiP2PManager();
  WifiP2PInfo? wifiP2PInfo;
  List<DiscoveredPeers> peers = [];
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;

  @override
  void initState() {
    super.initState();
    // WifiP2PManager.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  void _init() async {
    // Initialize the WifiP2PManager instance
    //await WifiP2PManager.instance.initialize();
    //await WifiP2PManager.instance.register();
    // Listen to WifiP2PInfo stream
    _streamWifiInfo = WifiP2PManager.instance.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event; // Assuming wifiP2PInfo is a member variable
      });
    });

    // Listen to discovered peers stream
    _streamPeers = WifiP2PManager.instance.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });
  }


  @override
  void dispose() {
    //WifiP2PManager.instance.closeSocketConnection();
    WidgetsBinding.instance.removeObserver(this);
    //WifiP2PManager.instance.unregister();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      WifiP2PManager.instance.unregister();
    } else if (state == AppLifecycleState.resumed) {
      WifiP2PManager.instance.register();
    }
  }

  Future startSocket() async {
    if (wifiP2PInfo != null) {
      bool started = await WifiP2PManager.instance.startSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/ConnectX/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          snack("$name connected to socket with address: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          snack(req);
        },
      );
      snack("open socket: $started");
    }
  }

  Future connectToSocket() async {
    if (wifiP2PInfo != null) {
      await WifiP2PManager.instance.connectToSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/ConnectX/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          snack("connected to socket: $address");
        },
        transferUpdate: (transfer) {
          // if (transfer.count == 0) transfer.cancelToken?.cancel();
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          snack(req);
        },
      );
    }
  }

  Future closeSocketConnection() async {
    bool closed = WifiP2PManager.instance.closeSocket();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "closed: $closed",
        ),
      ),
    );
  }

  Future sendMessage() async {
    WifiP2PManager.instance.sendStringToSocket(msgText.text);
  }

  Future sendFile(bool phone) async {
    String? filePath = await FilesystemPicker.open(
      context: context,
      rootDirectory: Directory(phone ? "/storage/emulated/0/" : "/storage/"),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
      showGoUp: true,
      folderIconColor: Colors.blue,
    );
    if (filePath == null) return;
    List<TransferUpdate>? updates =
    await WifiP2PManager.instance.sendFiletoSocket(
      [
        filePath,
        // "/storage/emulated/0/Download/Likee_7100105253123033459.mp4",
        // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
        // "/storage/0E64-4628/Flutter SDK/p2p_plugin.apk",
        // "/storage/emulated/0/Download/03 Omah Lay - Godly (NetNaija.com).mp3",
        // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
      ],
    );
    print(updates);
  }

  Future<void> showWifiOptionsMenu() async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000.0, 60.0, 10.0, 100.0), // position of the menu
      items: [
        PopupMenuItem(
          child: ListTile(
            title: const Text("Check Location Enabled"),
            onTap: () async {
              bool? isLocationEnabled = await WifiP2PManager.instance.checkLocationEnabled();
              snack(isLocationEnabled == true ? "Location is enabled" : "Location is disabled");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Check Wi-Fi Enabled"),
            onTap: () async {
              bool? isWifiEnabled = await WifiP2PManager.instance.checkWifiEnabled();
              snack(isWifiEnabled == true ? "Wi-Fi is enabled" : "Wi-Fi is disabled");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Ask Location Permission"),
            onTap: () async {
              bool permissionGranted = await WifiP2PManager.instance.askLocationPermission();
              snack(permissionGranted ? "Location permission granted" : "Location permission denied");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Ask Storage Permission"),
            onTap: () async {
              bool permissionGranted = await WifiP2PManager.instance.askStoragePermission();
              snack(permissionGranted ? "Storage permission granted" : "Storage permission denied");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Enable Location"),
            onTap: () async {
              bool locationEnabled = await WifiP2PManager.instance.enableLocationServices();
              snack(locationEnabled ? "Location enabled" : "Failed to enable location");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Enable Wi-Fi"),
            onTap: () async {
              bool wifiEnabled = await WifiP2PManager.instance.enableWifiServices();
              snack(wifiEnabled ? "Wi-Fi enabled" : "Failed to enable Wi-Fi");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Create Group"),
            onTap: () async {
              bool? created = await WifiP2PManager.instance.createGroup();
              snack(created != null && created ? "Group created" : "Failed to create group");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Remove Group/Disconnect"),
            onTap: () async {
              bool? removed = await WifiP2PManager.instance.removeGroup();
              snack(removed != null && removed ? "Group removed/disconnected" : "Failed to remove group");
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Get Group Info"),
            onTap: () async {
              var info = await WifiP2PManager.instance.groupInfo();
              showDialog(
                context: context,
                builder: (context) => Center(
                  child: Dialog(
                    child: SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("groupNetworkName: ${info?.groupNetworkName}"),
                            Text("passPhrase: ${info?.passPhrase}"),
                            Text("isGroupOwner: ${info?.isGroupOwner}"),
                            Text("clients: ${info?.clients}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Get IP"),
            onTap: () async {
              String? ip = await WifiP2PManager.instance.getIPAddress();
              snack(ip != null ? 'IP: $ip' : 'Failed to get IP');
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Discover"),
            onTap: () async {
              bool? discovering = await WifiP2PManager.instance.discover();
              snack(discovering != null && discovering ? 'Discovery started' : 'Discovery failed');
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Stop Discovery"),
            onTap: () async {
              bool? stopped = await WifiP2PManager.instance.stopDiscovery();
              snack(stopped != null && stopped ? 'Stopped discovery' : 'Failed to stop discovery');
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Open a Socket"),
            onTap: () async {
              await startSocket();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Connect to Socket"),
            onTap: () async {
              await connectToSocket();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            title: const Text("Close Socket"),
            onTap: () async {
              await closeSocketConnection();
            },
          ),
        ),
      ],
    );
  }


  void snack(String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
        ),
      ),
    );
  }

  void showPeerDetailsDialog(BuildContext context, DiscoveredPeers peer) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: AlertDialog(
          content: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("name: ${peer.deviceName}"),
                Text("address: ${peer.deviceAddress}"),
                Text("isGroupOwner: ${peer.isGroupOwner}"),
                Text("isServiceDiscoveryCapable: ${peer.isServiceDiscoveryCapable}"),
                Text("primaryDeviceType: ${peer.primaryDeviceType}"),
                Text("secondaryDeviceType: ${peer.secondaryDeviceType}"),
                Text("status: ${peer.status}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                bool? connected = await WifiP2PManager.instance.connect(peer.deviceAddress);
                snack("Connected: $connected");
              },
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wifi Direct Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: showWifiOptionsMenu,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  "IP: ${wifiP2PInfo == null ? "null" : wifiP2PInfo?.groupOwnerAddress}"),
              wifiP2PInfo != null
                  ? Text(
                  "connected: ${wifiP2PInfo?.isConnected}, isGroupOwner: ${wifiP2PInfo?.isGroupOwner}, groupFormed: ${wifiP2PInfo?.groupFormed}, groupOwnerAddress: ${wifiP2PInfo?.groupOwnerAddress}, clients: ${wifiP2PInfo?.clients}")
                  : const SizedBox.shrink(),
              const SizedBox(height: 10),
              const Text("PEERS:"),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true, // Allows the ListView to adjust height dynamically
                physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
                itemCount: peers.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Text(
                          peers[index].deviceName[0].toUpperCase(), // First letter of device name
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(peers[index].deviceName),
                      subtitle: Text("Address: ${peers[index].deviceAddress}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showPeerDetailsDialog(context, peers[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
              TextField(
                controller: msgText,
                decoration: const InputDecoration(
                  hintText: "message",
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  sendMessage();
                },
                child: const Text("Send Message"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await sendFile(true);
                },
                child: const Text("Send File"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
