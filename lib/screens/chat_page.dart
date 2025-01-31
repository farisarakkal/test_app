import 'dart:async';
import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../services/chat_storage.dart';
import '../services/wifi_p2p_manager.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class ChatPage extends StatefulWidget {
  final String deviceName;
  final String deviceAddress;
  final WifiP2PInfo? wifiP2PInfo; // Add wifiP2PInfo to the constructor

  const ChatPage({
    super.key,
    required this.deviceName,
    required this.deviceAddress,
    this.wifiP2PInfo, // Accept wifiP2PInfo in the constructor
  });

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  final ChatStorage _chatStorage = ChatStorage();
  List<DiscoveredPeers> peers = [];
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;
  String socketStatus = 'Socket inactive';


  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkConnectionAndSocket();
    _init();
  }

  void _init() async {
    // Listen to WifiP2PInfo stream
    if (widget.wifiP2PInfo != null) {
      setState(() {
        // Example: Use the passed wifiP2PInfo
        snack("Received WiFiP2PInfo: ${widget.wifiP2PInfo}");
      });
    }
  }

  Future<bool> _getConnectionStatus() async {
    return widget.wifiP2PInfo?.isConnected ?? false; // Use null-coalescing operator
  }

  Future<bool> _getGroupOwnerStatus() async {
    return widget.wifiP2PInfo ?.isGroupOwner ?? false; // Use null-coalescing operator
  }

  Future<void> _checkConnectionAndSocket() async {
    // Fetch connection and group owner status
    bool isConnected = await _getConnectionStatus(); // Await the connection status
    bool isGroupOwner = await _getGroupOwnerStatus(); // Await the group owner status

    try {
      if (isConnected) {
        if (isGroupOwner) {
          await startSocket();
          snack('Socket created!');
        } else {
          await connectToSocket();
          snack('Connected to socket!');
        }
      } else {
        snack('Not connected to any Wi-Fi P2P network.');
      }
    } catch (e) {
      snack('Error: ${e.toString()}');
    }
  }


  // Load existing messages when the page loads
  _loadMessages() async {
    List<ChatMessage> messages = await _chatStorage.loadChat(widget.deviceAddress);
    setState(() {
      _messages = messages;
    });
  }

  // Send a message
  _sendMessage(String message) async {
    if (message.isEmpty) return;
    // Create a new message
    ChatMessage chatMessage = ChatMessage(sender: 'Me', message: message);
    // Add the message to the list
    setState(() {
      _messages.add(chatMessage);
    });
    // Save the updated list to local storage
    await _chatStorage.saveChat(widget.deviceAddress, _messages);
    // Clear the text field
    _controller.clear();
  }

  Future startSocket() async {
    if (widget.wifiP2PInfo != null) {
      bool started = await WifiP2PManager.instance.startSocket(
        groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/ConnectX/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          snack("$name connected to socket with address: $address");
          setState(() {
            socketStatus = 'Socket active';  // Update socket status when connected
          });
          WifiP2PManager.instance.sendStringToSocket('Socket active');
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
          // Create a new message object for the received message
          ChatMessage receivedMessage = ChatMessage(sender: 'Other', message: req);
          // Add the received message to the list and update the state
          setState(() {
            _messages.add(receivedMessage);
          });
          // Save the updated chat list to local storage
          await _chatStorage.saveChat(widget.deviceAddress, _messages);
        },
      );
      snack("open socket: $started");
    }
  }

  Future connectToSocket() async {
    if (widget.wifiP2PInfo != null) {
      await WifiP2PManager.instance.connectToSocket(
          groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
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
            if (req == "Socket active") {
              // Update the AppBar subtitle to indicate the socket is active
              setState(() {
                socketStatus = "Socket active";  // This will update the subtitle in the AppBar
              });
            } else {
              // For regular messages, create a new message object and add it to the list
              ChatMessage receivedMessage = ChatMessage(sender: 'Other', message: req);
              setState(() {
                _messages.add(receivedMessage);
              });
              // Save the updated chat list to local storage
              await _chatStorage.saveChat(widget.deviceAddress, _messages);
            }
          }
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
      ],
    );
    print(updates);
  }

  Future<void> requestManageAllFilesPermissionAndSendFile() async {
    // Request permission to manage all files (MANAGE_EXTERNAL_STORAGE)
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      await sendFile(true);
    } else {
      print('Permission denied to manage all files.');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 11.0), // Raise title by 8 pixels
          child: Text(widget.deviceName),
        ),
        flexibleSpace: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 72.0, bottom: 3.0),
            child: Text(
              socketStatus,
              style: TextStyle(
                fontSize: 13, // Smaller font size for subtitle
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isSender = message.sender == 'Me'; // This will check if the message is from the sender (you)

                return Align(
                  alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isSender ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file),
                    onPressed: () async {
                      // Open file picker and send the selected file
                      await requestManageAllFilesPermissionAndSendFile();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,  // Removes the default border
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _sendMessage(_controller.text);
                      WifiP2PManager.instance.sendStringToSocket(_controller.text);
                    },
                  ),
                ],
              )

          ),
        ],
      ),
    );
  }
}