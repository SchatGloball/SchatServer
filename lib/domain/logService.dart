import 'package:schat_api/data/log/log.dart';
import 'package:schat_api/env.dart';

import '../data/db.dart';
int maxLogCheck = 0;
Future<int> createNewLog(String body, int userId, bool isError)async
{
  if(env.logLevel==0)
  { return 0;}

 final int id = await db.logs.insertOne(LogInsertRequest(body: body, userId: userId, error: isError, date: DateTime.now()));
 maxLogCheck++;
 deleteLog();
 return id;
}

void deleteLog()async
{
if(maxLogCheck >= 100)
 {
  await db.execute('''
      DELETE FROM logs 
      WHERE id NOT IN (
        SELECT id FROM logs 
        ORDER BY id DESC 
        LIMIT ${Env().maxLogString}
      )
    ''');
    maxLogCheck = 0;
 }
}