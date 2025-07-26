import 'dart:io';

startMigration()async
{
   Process processGenerate = await Process.start('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'], workingDirectory: '/app');
    var outputGenerate = processGenerate.stdout.listen((item) {
      print(String.fromCharCodes(item));}
);
   int exitCode = await processGenerate.exitCode;

  Process process = await Process.start('dart', ['run', 'stormberry', 'migrate', '--db=schat'], workingDirectory: '/app');
print(process.exitCode);
  var output = process.stdout.listen((item) {
      print(String.fromCharCodes(item));}
);

process.stdin.write('yes');
  process.stdin.write('\n');

  // Ждем завершения процесса и получаем результат
int exitCodee = await process.exitCode;
output.cancel();

}
