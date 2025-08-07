import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:bookfx/bookfx.dart';
import 'package:trump_quotes/fileOperate.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static _AppSetting setting = _AppSetting();

  // Test for JSON
  static var dataList;
  // Here I create a file named random which is for first page everyday quote use if it doesn't exist
  static OperateCacheFile opRandomFile = OperateCacheFile(filename: "random");
  late bool randomFileExists;
  static List<int> contentNumber = []; // Index use
  static List<Widget> pages = [];

  bool _isDataLoaded = false;

  static BookController bookController = BookController();

  @override
  void initState() {
    super.initState();
    setting.changeLocale = (Locale locale) {
      setState(() {
        setting._locale = locale;
        if (_isDataLoaded) {
          generatePages();
        }
      });
    };
    print("Start judge random file.");
    opRandomFile.fileExist().then((value) {
      randomFileExists = value;
      if (!randomFileExists) {
        print("Random file doesn't exist.");
        opRandomFile.createFile();
      } else {
        print("Random file exists.");
      }
    });
    print("Start JSON");
    rootBundle
        .loadString(
          'assets/quotes/trump_quotes_final_strictly_clean_reindexed.json',
        )
        .then((value) {
          dataList = json.decode(value);
          print("Init finished");
          print(dataList.length);
          _isDataLoaded = true;
          generatePages();

          String lastContent = "";
          for (int i = 1; i <= dataList.length; i++) {
            Map<String, dynamic> content = dataList[i.toString()];

            if (lastContent != content['category']['en']) {
              contentNumber.add(i);
              lastContent = content['category']['en'];
            }
          }
        });
  }

  void generatePages() {
    pages.clear();
    pages.add(CoverPage());
    pages.add(MagaPage());
    for (int i = 1; i <= dataList.length; i++) {
      Map<String, dynamic> content = dataList[i.toString()];

      int _calculateMaxLines(BoxConstraints constraints) {
        final lineHeight = 1.2; // 行高系数（根据实际字体调整）
        final cardHeight = constraints.maxHeight - 131; // 减去padding
        return (cardHeight / (19 * lineHeight)).floor(); // 40为初始fontSize
      }

      Widget ch = LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/background1.jpg'),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 15),
                Card(
                  margin: EdgeInsets.all(12),
                  child: Builder(
                    builder: (BuildContext context) {
                      String contentToShow;
                      switch (setting._locale) {
                        case const Locale('en'):
                          contentToShow = content['content']['en'];
                        default:
                          contentToShow = content['content']['zh'];
                      }
                      return AutoSizeText(
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          wordSpacing: 1.0,
                        ),
                        maxLines: _calculateMaxLines(constraints),
                        minFontSize: 12,
                        contentToShow,
                      );
                    },
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 100),
                    Builder(
                      builder: (BuildContext context) {
                        String fromToShow;
                        switch (setting._locale) {
                          case const Locale('en'):
                            fromToShow = content['from']['en'];
                          default:
                            fromToShow = content['from']['zh'];
                        }
                        return Flexible(
                          child: Text(
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            fromToShow,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      String getTitle() {
        switch (setting._locale) {
          case const Locale('en'):
            return content['category']['en'];
          default:
            return content['category']['zh'];
        }
      }

      pages.add(MyTemPage(title: getTitle(), child: ch, showmenu: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'trump_quotes',
      locale: setting._locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en', 'US'), Locale('zh', 'CN')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: AdPage(),
    );
  }
}

class AdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(child: Placeholder(), color: Colors.white),
      onTap: () {
        if (MyAppState.dataList != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FirstPage()),
          );
          print("Leave adpage");
        } else {
          print("Data not loaded yet. Waiting for data to load...");
        }
      },
    );
  }
}

class _AppSetting {
  _AppSetting();
  Null Function(Locale locale) changeLocale = (Locale locale) {};
  Locale _locale = Locale("en");
}

class MyTemPage extends StatefulWidget {
  MyTemPage({
    super.key,
    required this.title,
    required this.child,
    required this.showmenu,
  });
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
      fontSize: 20,
    );
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(widget.title, style: style),
          ),
          automaticallyImplyLeading: false,
          toolbarHeight: 30,
        ),
        body: Column(
          children: [
            Expanded(child: Container(child: widget.child)),
            BottomBar(showmenu: widget.showmenu),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.showmenu});
  final bool showmenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: showmenu,
            child: PopupMenuButton<String>(
              child: Icon(Icons.menu, size: 40),
              onSelected: (String string) {
                print("contents ${string.toString()}");
                if (string != 'None')
                  MyAppState.bookController.goTo(int.parse(string));
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuItem<String>>[
                    PopupMenuItem(
                      child: Text(
                        AppLocalizations.of(context)!.contents,
                        style: TextStyle(
                          backgroundColor: Color.fromARGB(255, 181, 14, 2),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: "None",
                    ),
                    for (var i in MyAppState.contentNumber)
                      PopupMenuItem(
                        child: Builder(
                          builder: (context) {
                            var textToShow;
                            switch (MyAppState.setting._locale) {
                              case const Locale('en'):
                                textToShow =
                                    MyAppState.dataList[i
                                        .toString()]['category']['en'];
                              default:
                                textToShow =
                                    MyAppState.dataList[i
                                        .toString()]['category']['zh'];
                            }
                            return Text(
                              textToShow,
                              style: TextStyle(fontSize: 16),
                            );
                          },
                        ),
                        value: (i + 2).toString(),
                      ),
                  ],
            ),
          ),
          SizedBox(),
          PopupMenuButton<String>(
            child: Icon(Icons.settings, size: 40),
            onSelected: (String string) {
              print(string.toString());
              if (string == "中文") {
                MyAppState.setting.changeLocale(Locale('zh'));
              } else if (string == "English") {
                MyAppState.setting.changeLocale(Locale('en'));
              } else {
                MyAppState.setting.changeLocale(Locale('en'));
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuItem<String>>[
                  PopupMenuItem(child: Text("English"), value: "English"),
                  PopupMenuItem(child: Text("中文"), value: "中文"),
                ],
          ),
        ],
      ),
    );
  }
}

class FirstPage extends MyTemPage {
  FirstPage({super.key})
    : super(title: "title", child: Placeholder(), showmenu: false);

  @override
  FirstPageState<FirstPage> createState() => FirstPageState();
}

class FirstPageState<T extends FirstPage> extends MyTemPageState<FirstPage> {
  // Number and content to show
  late Future<int> number;
  late Future<Map<String, dynamic>> content;

  // Read the random file to decide whether to generate a new random number
  @override
  void initState() {
    super.initState();
    number = getRandomNumber();
    content = getContent();
  }

  Future<int> getRandomNumber() async {
    int ret = 1;
    final contents = await MyAppState.opRandomFile.readFile();
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;
    int day = now.day;

    // Empty or out of date
    print("About to look contents in random file");
    print(contents);
    if (contents.length != 2) {
      print("Contents length is not 2");
      ret = generateNewRandom(now);
    } else {
      print("In firstpage init, parse random file, before look contents");
      final timeInFile = contents[0].split(",");
      print("After split contents");
      print(timeInFile);
      if (timeInFile.length != 3 ||
          int.parse(timeInFile[0]) != year ||
          int.parse(timeInFile[1]) != month ||
          int.parse(timeInFile[2]) != day) {
        ret = generateNewRandom(now);
      } else {
        ret = int.parse(contents[1]);
      }
    }
    return ret;
  }

  int randomGen(min, max) {
    var x = Random().nextInt(max) + min;
    return x.floor();
  }

  int generateNewRandom(DateTime now) {
    int ret = 1;
    int max = MyAppState.dataList!.length;
    ret = randomGen(1, max);
    print(ret);

    // Write the random file, format: year,month,day\number
    String content =
        now.year.toString() +
        ',' +
        now.month.toString() +
        ',' +
        now.day.toString() +
        Platform.lineTerminator +
        ret.toString();
    MyAppState.opRandomFile.writeFile(content);
    return ret;
  }

  // Prepare what to show
  Future<Map<String, dynamic>> getContent() async {
    print("In firstpage, check locale and decide what content to show");
    int n = await number;
    print(n);
    return MyAppState.dataList![n.toString()];
  }

  @override
  Widget build(BuildContext context) {
    widget.title = AppLocalizations.of(context)!.everyday_quote;
    int _calculateMaxLines(BoxConstraints constraints) {
      final lineHeight = 1.2; // 行高系数（根据实际字体调整）
      final cardHeight = constraints.maxHeight - 131; // 减去padding
      return (cardHeight / (19 * lineHeight)).floor(); // 40为初始fontSize
    }

    Widget ch = GestureDetector(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/background1.jpg'),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 15),
                Card(
                  margin: EdgeInsets.all(12),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: content,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("Loading");
                      }
                      if (snapshot.hasError) {
                        return Text("Error");
                      }
                      String contentToShow;
                      switch (MyAppState.setting._locale) {
                        case const Locale('en'):
                          contentToShow = snapshot.data!['content']['en'];
                        default:
                          contentToShow = snapshot.data!['content']['zh'];
                      }
                      return AutoSizeText(
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: _calculateMaxLines(constraints),
                        minFontSize: 12,
                        contentToShow,
                      );
                    },
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 100),
                    FutureBuilder<Map<String, dynamic>>(
                      future: content,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("Loading");
                        }
                        if (snapshot.hasError) {
                          return Text("Error");
                        }
                        String fromToShow;
                        switch (MyAppState.setting._locale) {
                          case const Locale('en'):
                            fromToShow = snapshot.data!['from']['en'];
                          default:
                            fromToShow = snapshot.data!['from']['zh'];
                        }
                        return Flexible(
                          child: Text(
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            fromToShow,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FrameWork()),
        );
        print("Tapped");
      },
    );
    widget.child = ch;

    return MyTemPage(title: widget.title, child: widget.child, showmenu: false);
  }
}

class CoverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 100),
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
        ),
      ),
    );
  }
}

class MagaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 300),
            Spacer(),
            BottomBar(showmenu: false),
          ],
        ),
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
  //BookController bookController = BookController();

  @override
  Widget build(BuildContext context) {
    print("Building FrameWork with ${MyAppState.pages.length} pages");
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: BookFx(
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height - 20,
        ),
        pageCount: MyAppState.pages.length,
        currentPage: (index) {
          return MyAppState.pages[index];
        },
        lastCallBack: (index) {
          print('Previous page $index');
        },
        nextCallBack: (index) {
          print('Next page $index');
        },
        nextPage: (index) {
          return MyAppState.pages[index];
        },
        controller: MyAppState.bookController,
      ),
    );
  }
}
