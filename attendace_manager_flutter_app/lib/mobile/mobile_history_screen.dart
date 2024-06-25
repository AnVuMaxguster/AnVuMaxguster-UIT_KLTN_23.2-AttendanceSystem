import 'package:attendace_manager_flutter_app/models/Class.dart';
import 'package:attendace_manager_flutter_app/provider/classes_changeNotifier.dart';
import 'package:attendace_manager_flutter_app/provider/riverpod_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

var normal_date_formatter=DateFormat("HH:mm dd/MM/yyyy");
class mobile_history_screen extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "History",
            style: GoogleFonts.nunito(
                textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        toolbarHeight: 70,
      ),
      body: ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: ref.watch(classes_Controller as ChangeNotifierProvider<ClassesChangeNotifier>).doneClasses.length,
          itemBuilder: (context,index)
          {
            Class currentClass=ref.watch(classes_Controller as ChangeNotifierProvider<ClassesChangeNotifier>).doneClasses[index]["class"] as Class;
            bool isPresent=ref.watch(classes_Controller as ChangeNotifierProvider<ClassesChangeNotifier>).doneClasses[index]["isPresent"] as bool;
            double attendancePercents=ref.watch(classes_Controller as ChangeNotifierProvider<ClassesChangeNotifier>).doneClasses[index]["attendancePercents"] as double;
            return OneHistoryInfoCard(currentClass.id, currentClass.subject, currentClass.start_time, currentClass.end_time, currentClass.className,isPresent,attendancePercents);
          }
      ),
    );
  }
}

class OneHistoryInfoCard extends ConsumerWidget
{
  int class_id;
  String class_subject;
  DateTime class_start;
  DateTime class_end;
  String class_name;
  bool isPresent;
  double attendancePercents;


  OneHistoryInfoCard(this.class_id, this.class_subject, this.class_start,
      this.class_end, this.class_name,this.isPresent, this.attendancePercents);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: (()
            {
              switch(attendancePercents)
                  {
                case 0:
                  return Colors.red;
                case <=0.3:
                  return Colors.orangeAccent;
                case <=0.5:
                  return Colors.blue;
                case <=0.8:
                  return Colors.cyan;
                case <=100:
                  return Colors.greenAccent;
              }
            })(),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(3,3)
              )
            ]
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
          child: Row(
            children: [
              ClipRect(
                child:Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 100,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        class_subject.toUpperCase()+" - "+class_name.toUpperCase(),
                        style: GoogleFonts.nunito(
                            textStyle: TextStyle(
                                fontSize: 22,
                                letterSpacing: 1.5,
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(20,0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: Axis.horizontal,
                        runSpacing: 10,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Class id: "+class_id.toString(),
                                style: GoogleFonts.nunito(
                                  textStyle: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                      backgroundColor: Colors.transparent
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  "Start time: "+normal_date_formatter.format(class_start),
                                  style: GoogleFonts.nunito(
                                      textStyle: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                          backgroundColor: Colors.transparent
                                      )
                                  ),
                                ),
                              ),
                              Text(
                                "End time: "+normal_date_formatter.format(class_end),
                                style: GoogleFonts.nunito(
                                    textStyle: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                        backgroundColor: Colors.transparent
                                    )
                                ),
                              ),
                            ],
                          ),
                          Transform.translate(
                            offset: Offset(50,0),
                            child: ClipRect(
                              child: Icon(
                                  ((){
                                    if(isPresent)
                                      return Icons.check_circle;
                                    return Icons.cancel;
                                  }
                                  )(),
                                color: Colors.white,
                                size: 50,
                              ),

                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
