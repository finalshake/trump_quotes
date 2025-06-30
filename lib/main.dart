import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:bookfx/bookfx.dart';
import 'package:trump_quotes/fileOperate.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatefulWidget{
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static _AppSetting setting = _AppSetting();

  //test for json
  static var dataList;
  // here I create a file named random which is for first page everyday quote use if it doesn't exist
  static OperateCacheFile opRandomFile = OperateCacheFile(filename: "random");
  late bool randomFileExists;
  static List<int> contentNumber = []; //index use
  static List<Widget> pages = [
    //FirstPage(),
    //CoverPage(),
    //MagaPage(),
    //MainContext(),
  ];
   
  @override
  void initState(){
    super.initState();
    setting.changeLocale = (Locale locale){
      setState(
        (){
          setting._locale = locale;
        }
      );
    };
    print("start judge random file.");
    opRandomFile.fileExist().then((value) {
      randomFileExists = value;
      if(!randomFileExists){
        print("random file doesn't exist.");
        opRandomFile.createFile();
      }else{
        print("random file exists.");
      }
    },);
    print("start json");
    rootBundle.loadString('assets/quotes/trump_quotes_reclassified_fixed.json').then((value) {
      dataList = json.decode(value);
      print("init finished");
      print(dataList.length);
    });
  }
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'trump_quotes',
/*       localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales){
        var result = supportedLocales.where((element) => element.languageCode == locale.languageCode);
        if(result.isNotEmpty){
          return locale;
        }
        return Locale('en');
      }, */
      locale: setting._locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en','US'),
        Locale('zh','CN'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: 
        AdPage(),
        //FirstPage(/* title:"what", child: Text("shit") */),
        //MagaPage(),
        //FrameWork(),
        //MainContext(),
    );
  }
}

class AdPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){

    return GestureDetector(
      child: Container(
        child: Placeholder(),
        color: Colors.white,
      ),
      onTap: (){
        Navigator.push( //跳转到第二个界面
          context,
          MaterialPageRoute(builder: (context) => FirstPage()),
        );
        print("leave adpage");
      },
      
    );
  }
}

class _AppSetting{
  _AppSetting();
  Null Function(Locale locale) changeLocale = (Locale locale){};
  Locale _locale = Locale("en");
}


class MyTemPage extends StatefulWidget {
  MyTemPage({super.key, required this.title, required this.child, required this.showmenu});
  String title;
  Widget child;
  bool showmenu;

  @override
  State<MyTemPage> createState() => MyTemPageState();
}

class MyTemPageState<T extends StatefulWidget> extends State<MyTemPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displaySmall!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
    );
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: true,
       
          appBar: AppBar(
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: 
                Text(
                  widget.title,
                  style: style,
                  //AppLocalizations.of(context)!.everyday_quote,
                ),
              
            ),
            automaticallyImplyLeading: false,
            toolbarHeight: 60,
          ),
          body: Column(
              children: [
                Expanded(
                  child: Container(
                    child: widget.child,
                  ),
                ),
                //Spacer(),
                BottomBar(showmenu: widget.showmenu,),
              ],
            ),
          ),
    );
  }
}

class BottomBar extends StatelessWidget{
  const BottomBar({
    super.key,
    required this.showmenu,
  });
  final bool showmenu;

  @override
  Widget build(BuildContext context){
    return Container(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: showmenu,
            child: IconButton(onPressed: (){sleep(100 as Duration);}, icon: Icon(Icons.menu)),
          ), 
          SizedBox(),
          
          PopupMenuButton<String>(
            child: Icon(Icons.settings),
            onSelected: (String string){
              print(string.toString());
              if(string == "中文") {
                MyAppState.setting.changeLocale(Locale('zh'));
              }else if(string == "English"){
                MyAppState.setting.changeLocale(Locale('en'));
              }else{
                MyAppState.setting.changeLocale(Locale('en'));
              }
      
            },
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
             PopupMenuItem(
                child: Text("English"),
                value: "English",
              ),
              PopupMenuItem(
                child: Text("中文"),
                value: "中文",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FirstPage extends MyTemPage{
  FirstPage({super.key,/* , required this.title, required this.child */}) : super(title: "title", child: Placeholder(), showmenu: false); 
  /* String title;
  Widget child; */

  @override
  FirstPageState<FirstPage> createState() => FirstPageState();
}
class FirstPageState<T extends FirstPage> extends MyTemPageState<FirstPage>{
  // number and content to show
  late Future<int> number;
  late Future<Map<String,dynamic>> content;

  //read the random file to decide wether should generate a new random number
  @override 
  void initState(){
    super.initState();
    number = getRandomNumber();
    content = getContent();
  }
  Future<int> getRandomNumber() async{
    //final firstPage = widget as FirstPage;
    int ret = 1;
    final contents = await MyAppState.opRandomFile.readFile();
    //MyAppState.opRandomFile.readFile().then((contents){
      DateTime now = DateTime.now();
      int year = now.year;
      int month = now.month;
      int day = now.day;

      //empty or out of date
      print("about to look contents in random file");
      print(contents);
      if(contents.length != 2){
        print("contents length is not 2");
        ret = generateNewRandom(now);
      }else{
        print("in firstpage init, parse random file, before look contents");
        final timeInFile = contents[0].split(",");
        print("after split contents");
        print(timeInFile);
        if(timeInFile.length != 3 || int.parse(timeInFile[0]) != year || int.parse(timeInFile[1]) != month || int.parse(timeInFile[2]) != day){
          ret = generateNewRandom(now);
        }else{
          ret = int.parse(contents[1]);
        }
      } 
        
    //});
    return ret;
  }
  
  randomGen(min, max) {
    //nextInt 方法生成一个从 0（包括）到 max（不包括）的非负随机整数
    var x = Random().nextInt(max) + min;
    //如果您不想返回整数，只需删除 floor() 方法
    return x.floor();
  }
  int generateNewRandom(DateTime now){
    int ret = 1;
    int max = MyAppState.dataList!.length;
    //final firstPage = widget as FirstPage;
    ret = randomGen(1, max);
    print(ret);

    //write the random file, format: year,month,day\nnumber
    String content = now.year.toString() + ',' + now.month.toString() + ',' + now.day.toString() + Platform.lineTerminator+ ret.toString();
    MyAppState.opRandomFile.writeFile(content);
    return ret;
  }

  //prepare what to show
  Future<Map<String,dynamic>> getContent() async{
    //final firstPage = widget as FirstPage;
    print("in firstpage, check locale and decide what content to show");
    int n = await number;
    print(n);
    // switch(MyAppState.setting._locale){
    //   case const Locale('en'): return MyAppState.dataList[n.toString()]["content"]["en"];
    //   default: return MyAppState.dataList[n.toString()]["content"]["zh"];
    // }    
    return MyAppState.dataList[n.toString()];
  }


  @override
  Widget build(BuildContext context){

    widget.title = AppLocalizations.of(context)!.everyday_quote;
    Widget ch = GestureDetector(
      child: Container(
        
        //color: Colors.white,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/images/background1.jpg'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50,),
            Card(
              margin: EdgeInsets.all(12),
              child: FutureBuilder<Map<String,dynamic>>(
                future: content,
                builder: (context, snapshot){
                  if(snapshot.connectionState == ConnectionState.waiting){
                    return Text("loading");
                  }
                  if (snapshot.hasError) {
                    return Text("error");
                  }
                  String contentToShow;
                  switch(MyAppState.setting._locale){
                    case const Locale('en'): contentToShow = snapshot.data!['content']['en'];
                    default: contentToShow = snapshot.data!['content']['zh'];
                  }
                  return Text(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    contentToShow,
                  );
                }
              ),
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 100,),
                FutureBuilder<Map<String,dynamic>>(
                  future: content,
                  builder: (context, snapshot){
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return Text("loading");
                    }
                    if (snapshot.hasError) {
                      return Text("error");
                    }
                    String fromToShow;
                    switch(MyAppState.setting._locale){
                      case const Locale('en'): fromToShow = snapshot.data!['from']['en'];
                      default: fromToShow = snapshot.data!['from']['zh'];
                    }
                    return Flexible(
                      child: Text(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        fromToShow,
                      ),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
        
      ),
      onTap: (){
        Navigator.push( //跳转到第二个界面
          context,
          MaterialPageRoute(builder: (context) => FrameWork()),
        );
        print("tapped");
      },
      
    );
    widget.child = ch;
    
    //MyAppState.pages.add(CoverPage());
    //MyAppState.pages.add(MagaPage());
    // add all pages
 /*    for(int i = 1; i <= MyAppState.dataList.length; i++){
      Map<String,dynamic> content = MyAppState.dataList[i.toString()];
      //String title, contentToShow, from;
      String lastContent = " ";
     
      if(lastContent != content['content']['en']){
        MyAppState.contentNumber.add(i);
        lastContent = content['content']['en'];
      }
      Widget ch = Container(
        //color: Colors.white,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/images/background1.jpg'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50,),
            Card(
              margin: EdgeInsets.all(12),
              child: Builder(
                builder:(BuildContext context){
                  
                  String contentToShow;
                  switch(MyAppState.setting._locale){
                    case const Locale('en'): contentToShow = content['content']['en'];
                    default: contentToShow = content['content']['zh'];
                  }
                  return Text(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    contentToShow,
                  );
                }
              ) 
            
            
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 100,),
                Builder(
                  builder: (BuildContext context){
                    String fromToShow;
                    switch(MyAppState.setting._locale){
                      case const Locale('en'): fromToShow = content['from']['en'];
                      default: fromToShow = content['from']['zh'];
                    }
                    return Flexible(
                      child: Text(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        fromToShow,
                      ),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
        
      );
      String getTitle() {
        switch(MyAppState.setting._locale){
          case const Locale('en'): return content['category']['en'];
          default: return content['category']['zh'];
        }
      }
      MyAppState.pages.add(MyTemPage(
        title: getTitle(),
        child: ch, 
        showmenu: true,
      ));
    } */

    return MyTemPage(title: widget.title, child: widget.child, showmenu: false,);
  }
}

class CoverPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 181, 14, 2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Container(
              child: Image.asset(
                  'assets/images/trump.png',
                  width: 300,
                  height: 300,
                ),
            ),
            SizedBox(
              height: 100,
            ),
            Text(
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
              AppLocalizations.of(context)!.booktitle,
            ),
            Spacer(),
            BottomBar(showmenu: false),
          ],
        )
      ),
    );
  }
}

class MagaPage extends StatelessWidget{
  @override
  Widget build(BuildContext context){

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
          
            Text(
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              AppLocalizations.of(context)!.maga,
            ),
            SizedBox(
              height: 300,
            ),
            Spacer(),
            BottomBar(showmenu: false),
          ],
        )
      ),
    );
  }
}


class FrameWork extends StatefulWidget {
  const FrameWork({Key? key}) : super(key: key);

  @override
  State<FrameWork> createState() => _FrameWork();
}

class _FrameWork extends State<FrameWork> {
  BookController bookController = BookController();
  
  @override
  Widget build(BuildContext context) {
    
    return Placeholder(
      child: BookFx(
          size: Size(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height-20),
          pageCount: MyAppState.pages.length,
          currentPage: (index) {
            return 
              MyAppState.pages[index];
          },
          lastCallBack: (index) {
            print('xxxxxx上一页  $index');
          },
          nextCallBack: (index) {
            print('next $index');
          },
          nextPage: (index) {
            return 
              MyAppState.pages[index];
          },
          controller: bookController),
    );
  }
}

// main context show widget
/* class MainContext extends StatefulWidget {
  const MainContext({Key? key}) : super(key: key);

  @override
  State<MainContext> createState() => _MainContext();
}

class _MainContext extends State<MainContext> {
  String data = '''''';
  TextEditingController textEditingController = TextEditingController();

  EBookController eBookController = EBookController();
  BookController bookController = BookController();

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/quotes/trump_formatted_v2.txt').then((value) {
      setState(() {
        data = value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('电子书翻页demo'),
        ),
        body: data.isEmpty
            ? const SizedBox()
            : Column(
                children: [
                  EBook(
                      maxWidth: 400,//MediaQuery.of(context).size.width,
                      eBookController: eBookController,
                      bookController: bookController,
                      duration: const Duration(milliseconds: 400),
                      fontHeight: 1.6,
                      data: data,
                      fontSize: eBookController.fontSize,
                      padding: const EdgeInsetsDirectional.all(15),
                      maxHeight: //MediaQuery.of(context).size.height - kToolbarHeight  -40,),
                600,),
                ],
              ));
  }
} */
