import 'package:flutter/cupertino.dart';
import 'package:flutter_app/debug/log/Log.dart';
import 'package:flutter_app/src/connector/CourseConnector.dart';
import 'package:flutter_app/src/taskcontrol/task/TaskModel.dart';
import 'package:flutter_app/ui/other/MyProgressDialog.dart';

class CourseByCourseIdTask extends TaskModel{
  static final String taskName = "CourseByCourseIdTask";
  String id;
  CourseByCourseIdTask(BuildContext context,this.id) : super(context, taskName);

  @override
  Future<TaskStatus> taskStart() async{
    MyProgressDialog.showProgressDialog(context, "getcourse");
    bool value = await CourseConnector.getCourseByCourseId(id);
    MyProgressDialog.hideProgressDialog();
    if( value ) {
      return TaskStatus.TaskSuccess;
    }else {
      return TaskStatus.TaskFail;
    }
  }


}