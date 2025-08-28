// このファイル内の関数は grind コマンドを通して実行可能なため ignore する
// ignore_for_file: unreachable_from_main

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async => grind(args);

/// `arb_translate` を利用して翻訳を行う。
///
/// デフォルト言語の arb ファイルを元にそれ以外の arb ファイルのフィールドを生成し、`l10n.dart` へ反映する。
@DefaultTask()
void translate() {
  // プロジェクトルートの API キーを取得する
  // MEMO(masaki): 現状は `masakisato.japan@gmail.com` が管理する GCP 上で作成されたキーになっている
  final apiKeyFile = File(p.join('../../', '.arb_translate_api_key'));
  final apiKey = apiKeyFile.existsSync()
      ? apiKeyFile.readAsStringSync().trim()
      : '';
  if (apiKey.isEmpty) {
    stderr.writeln('''
Please create a `.arb_translate_api_key` file in the project root and store the API key before using.
''');
    exit(1);
  }

  // トークン節約のために英語で記述し、翻訳精度向上のために適宜修正する追加文脈
  const context = '''
This application is a mobile app that stores users' document data.
Since it is mainly used by the government, strict wording is preferred in the translation.
''';

  // 以下の PR で提案されているモデルを利用する。
  // https://github.com/leancodepl/arb_translate/pull/24
  const model = 'gemini-2.0-flash';

  // 上記のフォーク元のリポジトリを利用してコマンドを実行し、arb ファイルへ翻訳されたフィールドを追加する。
  run(
    'fvm',
    arguments: [
      'dart',
      'run',
      'arb_translate',
      '--api-key',
      apiKey,
      '--context',
      context,
      '--model',
      model,
    ],
  );

  // arb ファイルのフィールドを `l10n.dart` へ反映するために `flutter gen-10n` を実行
  run('fvm', arguments: ['flutter', 'gen-l10n']);
}
