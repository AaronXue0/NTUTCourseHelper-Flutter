import 'package:flutter/cupertino.dart';
import 'package:flutter_app/generated/i18n.dart';
import 'package:flutter_app/src/connector/ISchoolPlusConnector.dart';
import 'package:flutter_app/src/store/Model.dart';
import 'package:flutter_app/src/taskcontrol/task/CheckCookiesTask.dart';
import 'package:flutter_app/src/taskcontrol/task/TaskModel.dart';
import 'package:flutter_app/ui/other/ErrorDialog.dart';
import 'package:flutter_app/ui/other/MyProgressDialog.dart';


class ISchoolPlusLoginTask extends TaskModel {
  static final String taskName =
      "ISchoolPlusLoginTask" + CheckCookiesTask.checkPlusISchool;
  ISchoolPlusLoginTask(BuildContext context)
      : super(context, taskName);

  @override
  Future<TaskStatus> taskStart() async {
    MyProgressDialog.showProgressDialog(context, S.current.loginISchoolPlus);
    String studentId = Model.instance.getAccount();
    String password = Model.instance.getPassword();
    ISchoolPlusConnectorStatus value =
    await ISchoolPlusConnector.login(studentId , password);
    MyProgressDialog.hideProgressDialog();
    if (value == ISchoolPlusConnectorStatus.LoginSuccess) {
      return TaskStatus.TaskSuccess;
    } else {
      _handleError();
      return TaskStatus.TaskFail;
    }
  }

  void _handleError() {
    ErrorDialogParameter parameter = ErrorDialogParameter(
      context: context,
      desc: S.current.loginISchoolPlusError,
    );
    ErrorDialog(parameter).show();
  }
}
