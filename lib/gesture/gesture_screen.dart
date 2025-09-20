import 'package:file_manager/gesture/gesture_painter.dart';
import 'package:file_manager/gesture/gesture_service.dart';
import 'package:file_manager/helper/db_helper.dart';
import 'package:file_manager/helper/gesture_model.dart';
import 'package:flutter/material.dart';

class GestureScreen extends StatefulWidget {
  const GestureScreen({super.key});

  @override
  State<GestureScreen> createState() => _GestureScreenState();
}

class _GestureScreenState extends State<GestureScreen> {
  bool isGestureEnable = false;
  List<GestureModel> allGestures = [];

  @override
  void initState() {
    super.initState();
    _fetchAllGestureFolder();
    _loadGestureState();
  }

  Future<void> _fetchAllGestureFolder() async {
    final getAllGesture = await DatabaseHelper.instance.getGestures();
    setState(() {
      allGestures = getAllGesture;
    });
  }

  Future<void> _loadGestureState() async {
    final value = await GestureService.getGestureEnable();
    setState(() {
      isGestureEnable = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text('Gesture'),
        actions: isGestureEnable ? [
          IconButton(
            onPressed: () {
              addGestureDialog();
            },
            icon: Icon(Icons.add, color: Colors.white, size: 25),
          ),
        ] : null,

          // IconButton(
          //   onPressed: () {},
          //   icon: Icon(
          //     Icons.location_on_outlined,
          //     color: Colors.white,
          //     size: 25,
          //   ),
          // ),

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(Icons.gesture_outlined),
              title: Text('Enable Gesture', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: isGestureEnable,
                onChanged: (value) async {
                  setState(() {
                    isGestureEnable = value;
                  });
                  await GestureService.setGestureEnable(value);
                  Navigator.pop(context, value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.blue,
              ),
            ),
          ),

          Expanded(
            child: isGestureEnable
                    ? FutureBuilder<List<GestureModel>>(
                      future: DatabaseHelper.instance.getGestures(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<List<GestureModel>> snapshot,
                      ) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final gestures = snapshot.data!;
                        if (gestures.isEmpty) {
                          return Center(child: Text("No gestures saved"));
                        }

                        return ListView.builder(
                          itemCount: gestures.length,
                          itemBuilder: (context, index) {
                            final gesture = gestures[index];
                            final points = gesture.points;

                            return Card(
                              margin: EdgeInsets.all(8),
                              child: ListTile(
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomPaint(painter: GesturePainter(points, fitToBox: true,),
                                  ),
                                ),

                                title: FutureBuilder<String?>(
                                  future: DatabaseHelper.instance
                                      .getFolderNameById(gesture.folderId!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Loading...");
                                    } else if (snapshot.hasError) {
                                      return Text("Error");
                                    } else if (!snapshot.hasData ||
                                        snapshot.data == null) {
                                      return Text("Unknown Folder");
                                    }
                                    return Text(
                                      "Folder name: ${snapshot.data}",
                                    );
                                  },
                                ),
                                subtitle: Text("Saved on ${gesture.createdAt}"),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await DatabaseHelper.instance.deleteGesture(
                                      gesture.id!,
                                    );
                                    setState(() {}); // UI refresh
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Gesture deleted"),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                    : Center(
                      child: Text(
                        "Gesture Disabled",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  void addGestureDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Text('Select Action'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openFolderDialog();
                      },
                      child: Text(
                        'Open Folder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),
                  ],
                ),
              ),
        );
      },
    );
  }

  Future<void> openFolderDialog() async {
    List folders = await DatabaseHelper.instance.getFolders(parentId: null);
    List folderAndFiles = folders;
    List<int?> navigationStack = [null];
    final selectedItem = await showDialog(
      context: context,
      builder: (context) {
        var selectedObj;

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: const Text(
                  'Open Folder',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child:
                      folderAndFiles.isEmpty
                          ? const Center(
                            child: Text("No folders or files available"),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            itemCount: folderAndFiles.length,
                            separatorBuilder:
                                (context, index) =>
                                    const Divider(thickness: 1, height: 1),
                            itemBuilder: (context, index) {
                              final item = folderAndFiles[index];
                              final isFolder = !item.isFile;

                              return ListTile(
                                leading: Icon(
                                  isFolder
                                      ? Icons.folder
                                      : Icons.insert_drive_file,
                                  color: isFolder ? Colors.grey : Colors.grey,
                                ),
                                title: Text(item.name),
                                subtitle: Text("${item.createdAt}"),
                                onTap: () async {
                                  if (isFolder) {
                                    // ✅ agar folder hai toh subfolders/files laao
                                    // currentParentId = item.id;
                                    navigationStack.add(item.id);
                                    final subItems = await DatabaseHelper
                                        .instance
                                        .getFolders(parentId: item.id);

                                    setState(() {
                                      folderAndFiles = subItems;
                                      selectedObj = item;
                                    });
                                  } else {
                                    Navigator.pop(context, item);
                                  }
                                },
                                selected: selectedObj?.id == item.id,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (navigationStack.length > 1) {
                            navigationStack.removeLast();
                            final parentId = navigationStack.last;

                            final parentItems = await DatabaseHelper.instance
                                .getFolders(parentId: parentId);

                            setState(() {
                              folderAndFiles = parentItems;
                              selectedObj = null;
                            });
                          }
                        },
                        child: Text(
                          "BACK",
                          style: TextStyle(
                            color:
                                navigationStack.length > 1
                                    ? Colors.blue : Colors.transparent,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, selectedObj,);
                        },
                        child: const Text("OK",
                          style: TextStyle(color: Colors.blue),),
                      ),
                    ],
                  ),
                ],
              ),
        );
      },
    );

    if (selectedItem != null) {
      if (selectedItem.isFile) {
        print("Selected File: ${selectedItem.name}");
        selectFolderDialog(
          selectedItem,
        );
      } else {
        print("Selected Folder: ${selectedItem.name}");
        selectFolderDialog(
          selectedItem,
        );
      }
    }
  }

  void selectFolderDialog(folder) {
    List<Offset?> points = [];
    final drawBoxKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text("Add a gesture"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Action: Open Folder - ${folder.name}"),
                    SizedBox(height: 16),

                    GestureDetector(
                      onPanUpdate: (details) {
                        final box =
                        drawBoxKey.currentContext!.findRenderObject() as RenderBox;
                        final localPos =
                        box.globalToLocal(details.globalPosition);

                        if (localPos.dx >= 0 &&
                            localPos.dy >= 0 &&
                            localPos.dx <= box.size.width &&
                            localPos.dy <= box.size.height) {
                          setState(() {
                            points.add(localPos);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        setState(() {
                          points.add(null);
                        });
                      },
                      child: Container(
                        key: drawBoxKey,
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomPaint(
                          painter: GesturePainter(points,  fitToBox: false),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final gesture = GestureModel(
                          folderId: folder.id,
                          points: points,
                          createdAt: DateTime.now(),
                        );

                        await DatabaseHelper.instance.insertGesture(gesture);
                        Navigator.pop(context);
                        _fetchAllGestureFolder();
                      },
                      child: Text("Save Gesture"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}
