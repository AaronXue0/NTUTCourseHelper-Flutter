import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/debug/log/Log.dart';
import 'package:flutter_app/src/connector/Connector.dart';
import 'package:flutter_app/src/connector/DioConnector.dart';
import 'package:flutter_app/src/permission/Permission.dart';
import 'package:flutter_app/src/store/Model.dart';
import 'package:flutter_app/src/store/json/CourseFileJson.dart';
import 'package:flutter_app/src/store/json/CourseTableJson.dart';
import 'package:flutter_app/src/store/json/CourseMainExtraJson.dart';
import 'package:flutter_app/src/taskcontrol/TaskHandler.dart';
import 'package:flutter_app/src/taskcontrol/task/ISchoolCourseFileTask.dart';
import 'package:flutter_app/ui/icon/MyIcons.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

class CourseFileScreen extends StatefulWidget {
  final CourseInfoJson courseInfo;

  CourseFileScreen(this.courseInfo);

  @override
  _CourseFileScreen createState() => _CourseFileScreen();
}

class _CourseFileScreen extends State<CourseFileScreen>
    with AutomaticKeepAliveClientMixin {
  List<CourseFileJson> courseFileList = List();
  SelectList selectList = SelectList();
  ReceivePort _port = ReceivePort();
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _flutterDownloaderInit();
    });
  }

  void _flutterDownloaderInit() async{
    WidgetsFlutterBinding.ensureInitialized();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState((){ });
    });
    FlutterDownloader.registerCallback(downloadCallback);
    _addTask();
  }


  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }



  void _addTask() async {
    bool checkPermission = await Permission.check(context);
    if( !checkPermission ){
      Fluttertoast.showToast(
          msg: "沒有權限",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }
    await Future.delayed(Duration(microseconds: 500));
    String courseId = widget.courseInfo.main.course.id;
    TaskHandler.instance.addTask(ISchoolCourseFileTask(context, courseId));
    await TaskHandler.instance.startTaskQueue(context);
    courseFileList =
        Model.instance.tempData[ISchoolCourseFileTask.courseFileListTempKey];
    selectList.addItems(courseFileList.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); //如果使用AutomaticKeepAliveClientMixin需要呼叫
    return _buildFileList();
  }

  Widget _buildFileList() {
    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              itemCount: courseFileList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque, //讓透明部分有反應
                  child: _buildCourseFile(index, courseFileList[index]),
                  onTap: () {
                    if (selectList.inSelectMode) {
                      selectList.setItemReverse(index);
                      setState(() {});
                    }else{
                      _downloadOneFile(index);
                    }
                  },
                  onLongPress: () {
                    if (!selectList.inSelectMode) {
                      selectList.setItemReverse(index);
                      setState(() {});
                    }
                  },
                );
              },
              separatorBuilder: (context, index) {
                // 顯示格線
                return Container(
                  color: Colors.black12,
                  height: 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> iconList = [
    Icon(
      MyIcon.file_pdf,
      color: Colors.red,
    ),
    Icon(
      MyIcon.file_word,
      color: Colors.blue,
    ),
    Icon(
      MyIcon.file_powerpoint,
      color: Colors.redAccent,
    ),
    Icon(
      MyIcon.file_excel,
      color: Colors.green,
    ),
    Icon(
      MyIcon.file_archive,
      color: Colors.blue,
    ),
    Icon(
      MyIcon.link,
      color: Colors.grey,
    ),
  ];

  Widget _buildCourseFile(int index, CourseFileJson courseFile) {
    return Container(
        color: selectList.getItemSelect(index) ? Colors.green : Colors.white,
        padding: EdgeInsets.all(10),
        child: Column(
          children: _buildFileItem(courseFile),
        ));
  }

  List<Widget> _buildFileItem(CourseFileJson courseFile) {
    List<Widget> widgetList = List();
    List<Widget> iconWidgetList = List();
    for (FileType fileType in courseFile.fileType) {
      iconWidgetList.add(iconList[fileType.type.index]);
    }
    widgetList.add(
      Row(
        children: [
          Column(
            children: iconWidgetList,
          ),
          Padding(
            padding: EdgeInsets.only(left: 10),
          ),
          Expanded(
            child: Text(courseFile.name),
          ),
          Text(courseFile.timeString),
        ],
      ),
    );
    return widgetList;
  }

  Future<String> _findLocalPath() async {
    final directory = Theme.of(context).platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<String> _getDownloadDir( String name ) async{
    var _localPath = (await _findLocalPath()) + '/$name';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    return savedDir.path;
  }


  void _downloadOneFile(int index) async{
    CourseFileJson courseFile = courseFileList[index];
    String path = await _getDownloadDir( widget.courseInfo.main.course.name );
    Log.d( path );
    String url = courseFile.fileType[0].fileUrl;
    await FlutterDownloader.enqueue(
      url:  url,
      savedDir: path,
      headers: Connector.getLoginHeaders(url),
      showNotification: true,
      // show download progress in status bar (for Android)
      openFileFromNotification:
      true, // click on notification to open downloaded file (for Android)
    );

  }


  @override
  bool get wantKeepAlive => true;
}

class SelectList {
  List<bool> _selectList = List();

  void addItem() {
    _selectList.add(false);
  }

  void addItems(int number) {
    for (int i = 0; i < number; i++) {
      addItem();
    }
  }

  void setItemSelect(int index, bool value) {
    if (index >= _selectList.length) {
      return;
    } else {
      _selectList[index] = value;
    }
  }

  void setItemReverse(int index) {
    if (index >= _selectList.length) {
      return;
    } else {
      _selectList[index] = !_selectList[index];
    }
  }

  bool getItemSelect(int index) {
    if (index >= _selectList.length) {
      return false;
    } else {
      return _selectList[index];
    }
  }

  bool get inSelectMode {
    bool select = false;
    for (bool value in _selectList) {
      select |= value;
    }
    return select;
  }

  void leaveSelectMode() {
    for (int i = 0; i < _selectList.length; i++) {
      _selectList[i] = false;
    }
  }
}