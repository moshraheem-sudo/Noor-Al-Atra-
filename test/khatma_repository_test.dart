import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_noor_alatra/repositories/khatma_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KhatmaRepository compiles, notifies and computes progress safely', () {
    final repo = KhatmaRepository();
    expect(repo, isNotNull);

    int notificationCount = 0;
    repo.addListener(() {
      notificationCount++;
    });

    repo.notifyListeners();
    expect(notificationCount, greaterThan(0));
    expect(repo.getJuzProgress(1), isNotNull);
  });
}
