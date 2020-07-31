import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'dart:isolate';

void printIt(Object x) {
  print('[Isolate] got $x');
}

void main(){
  test('send uri', ()async{
    final x = await Isolate.spawn(printIt, File('/etc/hosts').openRead());
  });
}