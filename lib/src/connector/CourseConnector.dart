import 'dart:convert';

import 'package:big5/big5.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/debug/log/Log.dart';
import 'package:flutter_app/src/store/Model.dart';
import 'package:flutter_app/src/store/json/CourseDetailJson.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:sprintf/sprintf.dart';
import 'Connector.dart';
import 'ConnectorParameter.dart';

enum CourseConnectorStatus {
  LoginSuccess,
  LoginFail,
  ConnectTimeOutError,
  NetworkError,
  UnknownError
}

class CourseConnector {
  static bool _isLogin = false;
  static final String _getLoginCourseUrl =
      "https://nportal.ntut.edu.tw/ssoIndex.do";
  static final String _postCourseUrl =
      "https://aps.ntut.edu.tw/course/tw/Select.jsp";
  static final String _checkLoginUrl =
      "https://aps.ntut.edu.tw/course/tw/Select.jsp";


  static Future<CourseConnectorStatus> login() async {
    String result;
    _isLogin = false;
    try {
      ConnectorParameter parameter;
      Document tagNode;
      List<Element> nodes;
      Map<String, String> data = {
        "apUrl": "https://aps.ntut.edu.tw/course/tw/courseSID.jsp",
        "apOu": "aa_0010-",
        "sso": "true",
        "datetime1": DateTime.now().millisecondsSinceEpoch.toString()
      };
      parameter = ConnectorParameter(_getLoginCourseUrl);
      parameter.data = data;
      result = await Connector.getDataByGet( parameter );
      tagNode = parse(result);
      nodes = tagNode.getElementsByTagName("input");
      data = Map();
      for (Element node in nodes) {
        String name = node.attributes['name'];
        String value = node.attributes['value'];
        data[name] = value;
      }
      String jumpUrl = tagNode.getElementsByTagName("form")[0].attributes["action"];
      parameter = ConnectorParameter(jumpUrl);
      parameter.data = data;
      Response response = await Connector.getDataByPostResponse( parameter );
      _isLogin = true;
      return CourseConnectorStatus.LoginSuccess;
    } on Exception catch (e) {
      Log.e(e.toString());
      return CourseConnectorStatus.LoginFail;
    }
  }


  static Future<bool> getCourseByCourseId(String courseId) async{
    try{
      ConnectorParameter parameter;
      Document tagNode;
      List<Element> nodes;
      Map<String, String> data = {
        "code": courseId,
        "format": "-1",
      };
      parameter = ConnectorParameter(_postCourseUrl);
      parameter.data = data;
      String result = await Connector.getDataByPost( parameter );
      tagNode = parse(result);
      nodes = tagNode.getElementsByTagName("a");
      for( Element node in nodes){
        Log.d( node.attributes["herf"] );
        Log.d( node.innerHtml );
      }
      return true;
    }on Exception catch(e){
      //throw e;
      Log.e(e.toString());
      return false;
    }
  }

  static Future<bool> getSemesterByStudentId(String studentId) async{
    try{
      ConnectorParameter parameter;
      Document tagNode;
      List<Element> nodes;
      Map<String, String> data = {
        "code": studentId,
        "format": "-3",
      };
      parameter = ConnectorParameter( _postCourseUrl );
      parameter.data = data;
      parameter.charsetName  = 'big5';
      Response response = await Connector.getDataByPostResponse( parameter );
      tagNode = parse(response.toString());
      nodes = tagNode.getElementsByTagName("a");
      for( Element node in nodes){
        Log.d( node.attributes["href"] );
        Log.d( node.innerHtml );
      }
      return true;
    }on Exception catch(e){
      //throw e;
      Log.e(e.toString());
      return false;
    }
  }

  static String strQ2B(String input)
  {
    List<int> newString = List();
    for (int c in input.codeUnits)
    {
      if ( c == 12288)
      {
        c = 32;
        continue;
      }
      if (c > 65280 && c< 65375){
        c = (c - 65248);
      }
      newString.add(c);
    }
    return String.fromCharCodes(newString);
  }




  static Future<CourseTableJson> getCourseByStudentId(String studentId , String year , String semester) async{
    try{
      ConnectorParameter parameter;
      Document tagNode;
      Element node;
      List<Element> courseNodes , nodesOne , nodes;
      CourseTableJson courseTable = CourseTableJson();
      courseTable.setCourseSemester(year, semester);

      Map<String, String> data = {
        "code": studentId,
        "format": "-2",
        "year" : year ,
        "sem" : semester ,
      };
      parameter = ConnectorParameter( _postCourseUrl );
      parameter.data = data;
      parameter.charsetName  = 'big5';
      Response response = await Connector.getDataByPostResponse( parameter );
      tagNode = parse(response.toString());
      node = tagNode.getElementsByTagName("table")[1];
      courseNodes = node.getElementsByTagName("tr");

      for ( int i = 2 ; i < courseNodes.length-1 ; i++){

        CourseDetailJson courseDetail = CourseDetailJson();
        CourseJson course = CourseJson();

        nodesOne = courseNodes[i].getElementsByTagName("td");

        //取得課號
        nodes = nodesOne[0].getElementsByTagName("a");
        if ( nodes.length >= 1 ){
          course.id   = nodes[0].text;
          course.href = nodes[0].attributes["href"];
        }

        //取的課程名稱/課程連結
        nodes = nodesOne[1].getElementsByTagName("a");
        if ( nodes.length >= 1 ){
          course.name = nodes[0].innerHtml;
        }else{
          course.name = nodesOne[1].text;
        }

        courseDetail.course = course;

        //取得老師名稱
        for( Element node in nodesOne[6].getElementsByTagName("a") ){
          TeacherJson teacher = TeacherJson();
          teacher.name = node.text;
          teacher.href = node.attributes["href"];
          courseDetail.addTeacher( teacher );
        }

        //取得教室名稱
        List<ClassroomJson> classroomList = List();
        for( Element node in nodesOne[15].getElementsByTagName("a") ){
          ClassroomJson classroom = ClassroomJson();
          classroom.name = node.text;
          classroom.href = node.attributes["href"];
          classroomList.add( classroom );
        }
        int courseDay = 0;
        bool add = false;
        for( int j = 8 ; j < 8 + 7 ; j++ ){
          String time = nodesOne[j].text;
          //計算教室
          if( classroomList.length >= 1){
            int classroomIndex = ( courseDay < classroomList.length ) ? courseDay : classroomList.length-1;
            courseDetail.classroom = classroomList[ classroomIndex ];
          }
          courseDay++;
          //加入課程時間
          add |= courseTable.setCourseDetailByTimeString( Day.values[ j - 8 ] , time, courseDetail);
        }
        if( !add ){  //代表課程沒有時間
          courseTable.setCourseDetailByTime( Day.UnKnown, SectionNumber.T_UnKnown, courseDetail);
        }
      }
      //Log.d( courseTable.toString() );
      return courseTable;
    }on Exception catch(e){
      //throw e;
      Log.e(e.toString());
      return null;
    }
  }


  static bool get isLogin {
    return _isLogin;
  }

  static Future<bool> checkLogin() async {
    Log.d("Course CheckLogin");
    ConnectorParameter parameter;
    _isLogin = false;
    try {
      parameter = ConnectorParameter(_checkLoginUrl);
      parameter.charsetName = "big5";
      String result = await Connector.getDataByGet(parameter);
      if (result.isEmpty || result.contains("尚未登錄入口網站")) {
        return false;
      } else {
        Log.d("Course Is Readly Login");
        _isLogin = true;
        return true;
      }
    } on Exception catch (e) {
      //throw e;
      Log.e(e.toString());
      return false;
    }
  }

}