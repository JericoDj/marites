import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  final cliPath = r'C:\Users\dejes\StudioProjects\ ADA-AI-ASSISTANT\gemma_local_ai\llama_prebuilt\llama-cli.exe';
  final modelPath = r'C:\Users\dejes\StudioProjects\ ADA-AI-ASSISTANT\gemma-3-4b-it-Q3_K_M.gguf';

  final process = await Process.start(
    cliPath,
    [
      '-m', modelPath,
      '-cnv',
      '-t', '8',
      '-c', '2048',
      '-n', '128',
      '--no-display-prompt',
      '--log-disable',
    ],
  );

  print("Process started...");

  StringBuffer buffer = StringBuffer();
  bool sentInput = false;

  process.stdout.transform(utf8.decoder).listen((text) {
    buffer.write(text);
    print("STDOUT Chunk: '${text.replaceAll('\n', r'\n').replaceAll('\r', r'\r')}'");
    
    if (text.contains('> ') && !sentInput) {
      print("Sending input 'hi'...");
      sentInput = true;
      process.stdin.writeln("hi");
    } else if (text.contains('> ') && sentInput) {
      print("Got second prompt, exiting.");
      process.kill();
      exit(0);
    }
  });
}
