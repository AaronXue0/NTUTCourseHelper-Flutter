import 'package:flutter_app/debug/log/Log.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:quiver/core.dart';
import 'package:sprintf/sprintf.dart';
import '../JsonInit.dart';
part 'NewAnnouncementJson.g.dart';

@JsonSerializable()
class NewAnnouncementJsonList {
  List<NewAnnouncementJson> newAnnouncementList;
  NewAnnouncementJsonList({this.newAnnouncementList}) {
    newAnnouncementList = newAnnouncementList ?? List();
  }

  bool addNewAnnouncement(NewAnnouncementJson newAnnouncement) {
    bool pass = true;
    for (NewAnnouncementJson value in newAnnouncementList) {
      if (value.messageId == newAnnouncement.messageId) {
        // 利用messageId辨識是否相同
        value.isRead = newAnnouncement.isRead;
        pass = false;
        break;
      }
    }
    if (pass) {
      Log.d(sprintf("add : %s", [newAnnouncement.toString()]));
      newAnnouncementList.add(newAnnouncement);
      newAnnouncementList.sort((a, b) => b.time.compareTo(a.time)); //排序
    }
    return pass;
  }

  bool get isEmpty {
    return newAnnouncementList.length == 0;
  }

  factory NewAnnouncementJsonList.fromJson(Map<String, dynamic> json) =>
      _$NewAnnouncementJsonListFromJson(json);
  Map<String, dynamic> toJson() => _$NewAnnouncementJsonListToJson(this);

  @override
  String toString() {
    return sprintf("---------newAnnouncementList-------- \n%s \n",
        [newAnnouncementList.toString()]);
  }
}

@JsonSerializable()
class NewAnnouncementJson {
  String title;
  String detail;
  String sender;
  String courseId;
  String courseName;
  String messageId;
  bool isRead;
  DateTime time;

  NewAnnouncementJson(
      {this.title,
      this.detail,
      this.sender,
      this.courseId,
      this.courseName,
      this.messageId,
      this.isRead,
      this.time}) {
    title = JsonInit.stringInit(title);
    detail = JsonInit.stringInit(detail);
    sender = JsonInit.stringInit(sender);
    courseId = JsonInit.stringInit(courseId);
    courseName = JsonInit.stringInit(courseName);
    messageId = JsonInit.stringInit(messageId);
  }

  get timeString {
    var formatter = DateFormat.yMd().add_jm();
    String formatted = formatter.format(time);
    return formatted;
  }

  bool get isEmpty {
    return title.isEmpty &&
        detail.isEmpty &&
        sender.isEmpty &&
        courseId.isEmpty &&
        courseName.isEmpty &&
        messageId.isEmpty;
  }

  factory NewAnnouncementJson.fromJson(Map<String, dynamic> json) =>
      _$NewAnnouncementJsonFromJson(json);
  Map<String, dynamic> toJson() => _$NewAnnouncementJsonToJson(this);
  @override
  String toString() {
    var formatter = DateFormat.yMd().add_jm();
    String formatted = formatter.format(time);
    return sprintf(
        ""
                "title      :%s \n" +
            "sender     :%s \n" +
            "messageId  :%s \n" +
            "courseName :%s \n" +
            "postTime   :%s \n",
        [title, sender, messageId, courseName, formatted]);
  }
}
