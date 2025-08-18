import 'package:file_manager/helper/folder_model.dart';
import 'package:file_manager/helper/db_helper.dart';
import 'package:file_manager/subfolder_screen.dart';
import 'package:file_manager/setting_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen>{

  Set<Folder> selectedFiles = {};
  bool multiSelectMode = false;
  Folder? selectedFolder;
  List<Folder> folders = [];
  Folder? dragSingleFile;
  bool listView = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    folders = await DatabaseHelper.instance.getFolders();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final List<Folder> onlyFolders = folders.where((f) => !f.isFile).toList();
    final List<Folder> onlyFiles = folders.where((f) => f.isFile).toList();

    final bool showFolderLabel = onlyFolders.isNotEmpty;
    final bool showFileLabel = onlyFiles.isNotEmpty;
    final int folderCount = onlyFolders.length;
    final int fileCount = onlyFiles.length;
    final int itemCount =
        (showFolderLabel ? 1 : 0) + folderCount + (showFileLabel ? 1 : 0) + fileCount;


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          title: Text('File Manager'),
        ),
        drawer: settingDrawer(context),

        body: listView
            ? ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return listViewMode(index, onlyFolders, onlyFiles, folderCount, fileCount, showFolderLabel, showFileLabel);
          },
        )
            : gridViewMode(onlyFolders, onlyFiles),

        floatingActionButton: customFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      ),
    );
  }

  Widget listViewMode(
      int index,
      List<Folder> onlyFolders,
      List<Folder> onlyFiles,
      int folderCount,
      int fileCount,
      bool showFolderLabel,
      bool showFileLabel,
      ) {
    int i = 0;

    if (showFolderLabel) {
      if (index == i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "FOLDERS",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: multiSelectMode
                    ? [
                  IconButton(
                    icon: Icon(Icons.clear),
                    tooltip: 'Clear selection',
                    onPressed: () {
                      setState(() {
                        selectedFiles.clear();
                        multiSelectMode = false;
                      });
                    },
                  ),
                ]
                    : [
                  IconButton(
                    icon:
                    Icon(listView ? Icons.view_list : Icons.grid_view),
                    onPressed: () {
                      setState(() {
                        listView = !listView;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }
      i++;
    }

    if (index < i + folderCount) {
      final folder = onlyFolders[index - i];
      return _FolderFileCard(folder, folder == selectedFolder, index - i);
    }
    i += folderCount;

    if (showFileLabel) {
      if (index == i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Text(
            "FILES",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700]),
          ),
        );
      }
      i++;
    }

    final file = onlyFiles[index - i];
    return _FolderFileCard(file, file == selectedFolder, index - i);
  }

  Widget gridViewMode(List<Folder> folders, List<Folder> files) {
    List<Widget> children = [];

    if (folders.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("FOLDERS", style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Row(
                children: multiSelectMode
                    ? [
                  IconButton(
                    icon: Icon(Icons.clear),
                    tooltip: 'Clear selection',
                    onPressed: () {
                      setState(() {
                        selectedFiles.clear();
                        multiSelectMode = false;
                      });
                    },
                  ),
                ]
                    : [
                  IconButton(
                    icon: Icon(listView ? Icons.view_list : Icons.grid_view),
                    onPressed: () {
                      setState(() {
                        listView = !listView;
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      );

      children.add(GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: folders.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _FolderFileCard(folder, folder == selectedFolder, index);
        },
      ));
    }

    if (files.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Text("FILES", style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
      );

      children.add(GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: files.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final file = files[index];
          return _FolderFileCard(file, file == selectedFolder, index);
        },
      ));
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Drawer settingDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.indigo),
            padding: const EdgeInsets.only(top: 40, left: 25, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 32,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 30,
                    child: Icon(
                      Icons.person_2_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.green),
            title: Text('Settings', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget customFAB() {
    return Container(
      margin: EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              AddFilePicker();
            },
            child: Icon(Icons.file_present_sharp, color: Colors.white),
          ),
          Container(
            height: 26,
            width: 2,
            margin: EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),
          GestureDetector(
            onTap: () {
              createFolderDialog();
            },
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _FolderFileCard(Folder folder, bool isSelected, int index) {
    final isFile = folder.isFile;
    final isMultiSelected = multiSelectMode && selectedFiles.contains(folder);
    final draggableData = isMultiSelected ? selectedFiles.toList() : [folder];

    // Widget tile = folderFileListTile(folder);
    Widget tile = listView
        ? folderFileListTile(folder)
        : folderFileGridTile(folder);
    if (isFile) {
      return Card(
        key: ValueKey(folder.name + folder.createdAt.toString()),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: isMultiSelected
            ? Colors.blue.shade100
            : (isSelected ? Colors.grey.shade300 : Colors.white),
        child: GestureDetector(
          onTap: () {
            if (multiSelectMode) {
              setState(() {
                if (selectedFiles.contains(folder)) {
                  selectedFiles.remove(folder);
                  if (selectedFiles.isEmpty) multiSelectMode = false;
                } else {
                  selectedFiles.add(folder);
                }
              });
            } else {
              if (folder.filePath != null) {
                OpenFilex.open(folder.filePath!);
              }
            }
          },
          onLongPress: () {
            setState(() {
              multiSelectMode = true;
              selectedFiles.add(folder);
            });
          },
          child: Draggable<List<Folder>>(
            data: isMultiSelected ? selectedFiles.toList() : [folder],
            feedback: dragFeedbackUi(isMultiSelected ? selectedFiles : {folder}),
            childWhenDragging: Opacity(opacity: 0.2, child: tile),
            child: tile,
          ),
        ),
      );
    } else {

      return Card(
        key: ValueKey(folder.name + folder.createdAt.toString()),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        color: isSelected ? Colors.grey.shade300 : Colors.white,
        child: DragTarget<List<Folder>>(
          onWillAcceptWithDetails: (details) =>
              _canAcceptDrop(folder, details.data),
          onAcceptWithDetails: (details) async {
            List<Folder> dragged = details.data;
            for (var item in dragged) {
              item.parentId = folder.id;
              await DatabaseHelper.instance.updateFolder(item);
            }
            selectedFiles.clear();
            multiSelectMode = false;
            await _loadFolders();
          },
          builder: (context, candidateData, rejectedData) {
            return Draggable<List<Folder>>(
              data: draggableData,
              feedback: dragFeedbackUi(draggableData.toSet()),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: Container(
                decoration: BoxDecoration(
                  border: candidateData.isNotEmpty
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: tile,
              ),
            );
          },
        ),
      );
    }

  }
  bool _canAcceptDrop(Folder target, List<Folder> dragged) {
    return dragged.every((f) => f.id != target.id);
  }

  Widget dragFeedbackUi(Set<Folder> selectedFiles) {
    final count = selectedFiles.length;
    final displayText = count == 1 ? selectedFiles.first.name : "$count files selected";

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Icon(Icons.insert_drive_file, size: 28, color: Colors.grey),
          title: Text(
            displayText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
        ),
      ),
    );
  }


  Widget folderFileListTile(Folder folder) {
    return ListTile(
      leading: Icon(
        folder.isFile ? Icons.insert_drive_file : Icons.folder,
        color: folder.isFile ? Colors.grey.shade400 : Colors.grey,
        size: 40,
      ),
      title: Text(folder.name),
      subtitle: Text('${timeAgo(folder.createdAt)} ago'),
      trailing:  multiSelectMode && folder.isFile
          ? Icon(
        selectedFiles.contains(folder)
            ? Icons.check_box
            : Icons.check_box_outline_blank,
        color: Colors.blue,
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              if (value == 'rename') {
                renameDialog(folder);
              } else if (value == 'delete') {
                deleteDialog(folder);
              }
            },
          )
        ],
      ),

      onTap: () {
        if (multiSelectMode) {
          setState(() {
            if (selectedFiles.contains(folder)) {
              selectedFiles.remove(folder);
              if (selectedFiles.isEmpty) multiSelectMode = false;
            } else {
              selectedFiles.add(folder);
            }
          });
        } else {
          if (folder.isFile && folder.filePath != null) {
            OpenFilex.open(folder.filePath!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => subFolder(folder: folder),
              ),
            );
          }
        }
      },
    );
  }

  Widget folderFileGridTile(Folder folder) {
    final isSelected = selectedFiles.contains(folder);

    return GestureDetector(
      onTap: () {
        if (multiSelectMode) {
          setState(() {
            if (selectedFiles.contains(folder)) {
              selectedFiles.remove(folder);
              if (selectedFiles.isEmpty) multiSelectMode = false;
            } else {
              selectedFiles.add(folder);
            }
          });
        } else {
          if (folder.isFile && folder.filePath != null) {
            OpenFilex.open(folder.filePath!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => subFolder(folder: folder),
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  folder.isFile ? Icons.insert_drive_file : Icons.folder,
                  size: 36,
                  color: folder.isFile ? Colors.grey.shade400 : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  folder.name,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${timeAgo(folder.createdAt)} ago',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (multiSelectMode && folder.isFile)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.blue,
                size: 20,
              ),
            ),

          if (!multiSelectMode)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'rename') {
                    renameDialog(folder);
                  } else if (value == 'delete') {
                    deleteDialog(folder);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> AddFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = result.files.single;

      Folder file = Folder(
        name: pickedFile.name,
        createdAt: DateTime.now(),
        isFile: true,
        filePath: pickedFile.path!,
        parentId: null,
      );

      await DatabaseHelper.instance.insertFolder(file);
      await _loadFolders();
    }
  }

  void createFolderDialog() {
    TextEditingController _controller = TextEditingController();
    bool showError = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Create Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a name for your new folder:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Folder name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: showError ? 'Folder name cannot be empty' : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () {
                  final name = _controller.text.trim();
                  if (name.isEmpty) {
                    setState(() => showError = true);
                  } else {
                    this.setState(() {
                      _addFolder(name);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('CREATE', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
      },
    );
  }

  void renameDialog(Folder folder) {
    TextEditingController _controller = TextEditingController(text: folder.name);
    bool showError = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Rename Folder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a new name for the folder:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Folder name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: showError ? 'Folder name cannot be empty' : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () async {
                  String newName = _controller.text.trim();
                  if (newName.isEmpty) {
                    setState(() => showError = true);
                  } else {
                    folder.name = newName;
                    await DatabaseHelper.instance.updateFolder(folder);
                    Navigator.pop(context);
                    _loadFolders();
                  }
                },
                child: Text('RENAME', style: TextStyle(color: Colors.blue)),
              ),

            ],
          ),
        );
      },
    );
  }

  void deleteDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Delete Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this folder?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              SizedBox(height: 12),
              Text(
                folder.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.instance.deleteFolder(folder.id!);
                Navigator.pop(context);
                _loadFolders();
              },
              child: Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _addFolder(String name) async {
    Folder newFolder = Folder(
      name: name,
      createdAt: DateTime.now(),
      isFile: false,
      parentId: null,
    );
    await DatabaseHelper.instance.insertFolder(newFolder);
    _loadFolders();
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "0 minutes";
    if (diff.inHours < 1) return "${diff.inMinutes} minutes";
    if (diff.inDays < 1) return "${diff.inHours} hours";
    if (diff.inDays < 7) return "${diff.inDays} days";
    return "${(diff.inDays / 7).floor()} week";
  }

}
