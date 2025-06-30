import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class OperateCacheFile {
  OperateCacheFile({required String this.filename});
  String filename;

  Future <String> get _localPath async{
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  Future<File> get _localFile async{
    final path = await _localPath;
    print("file path is $path/${this.filename}");
    return File('$path/${this.filename}');
  }
  Future<bool> fileExist() async {
    File file = await _localFile;
    print("file.exists: ${file.existsSync()}");
    return file.existsSync();
  }
  //create
  void createFile() async {
    final file = await _localFile;
    file.create();
  }
  //read
  Future<List<String>> readFile() async{
    try{
      final file = await _localFile;
      final contents = await file.readAsLines();
      return contents;
    }catch(e){
      return new List.empty();
    }
  }
  //write
  void writeFile(String contents) async{
    final file = await _localFile;
    file.writeAsString(contents);
  }
}