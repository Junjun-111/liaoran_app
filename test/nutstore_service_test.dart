// 坚果云 WebDAV 列表解析测试：覆盖真实返回格式与异常格式。
import 'package:flutter_test/flutter_test.dart';

import 'package:liaoran_app/services/nutstore_service.dart';

void main() {
  test('解析标准 207 响应：跳过目录、保留 json 备份', () {
    const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/dav/liaoran-backups/</D:href>
    <D:propstat>
      <D:prop><D:resourcetype><D:collection/></D:resourcetype></D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
  <D:response>
    <D:href>/dav/liaoran-backups/backup_20260819_185600.json</D:href>
    <D:propstat><D:status>HTTP/1.1 200 OK</D:status></D:propstat>
  </D:response>
  <D:response>
    <D:href>/dav/liaoran-backups/backup_20260818_090000.json</D:href>
    <D:propstat><D:status>HTTP/1.1 200 OK</D:status></D:propstat>
  </D:response>
</D:multistatus>
''';
    final names = NutstoreService.parseBackupNames(xml);
    expect(names, contains('backup_20260819_185600.json'));
    expect(names, contains('backup_20260818_090000.json'));
    expect(names, hasLength(2));
  });

  test('解析完整 URL 形式与空前缀的 href', () {
    const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<multistatus xmlns="DAV:">
  <response>
    <href>https://dav.jianguoyun.com/dav/liaoran-backups/backup_a.json</href>
  </response>
  <response>
    <href>https://dav.jianguoyun.com/dav/liaoran-backups/backup_b.json</href>
  </response>
</multistatus>
''';
    final names = NutstoreService.parseBackupNames(xml);
    expect(names, containsAll(['backup_a.json', 'backup_b.json']));
  });

  test('百分号编码的文件名会被解码', () {
    const xml = '''
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/dav/liaoran-backups/backup_%E6%B5%8B%E8%AF%95.json</D:href>
  </D:response>
</D:multistatus>
''';
    final names = NutstoreService.parseBackupNames(xml);
    expect(names, contains('backup_测试.json'));
  });

  test('空响应或损坏 XML 返回空列表而不是抛错', () {
    expect(NutstoreService.parseBackupNames(''), isEmpty);
    expect(NutstoreService.parseBackupNames('<not xml'), isEmpty);
    expect(NutstoreService.parseBackupNames('OK'), isEmpty);
  });

  test('非 json 文件不会被当作备份', () {
    const xml = '''
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/dav/liaoran-backups/readme.txt</D:href>
  </D:response>
  <D:response>
    <D:href>/dav/liaoran-backups/backup_1.json</D:href>
  </D:response>
</D:multistatus>
''';
    final names = NutstoreService.parseBackupNames(xml);
    expect(names, ['backup_1.json']);
  });
}
