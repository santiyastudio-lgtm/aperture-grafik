import '../../domain/models.dart';

class Strings {
  const Strings(this.language);
  final AppLanguage language;

  bool get isRu => language == AppLanguage.russian;
  String get appName => 'Aperture Grafik';
  String get home => isRu ? 'Главная' : 'Home';
  String get calendar => isRu ? 'Календарь' : 'Calendar';
  String get statistics => isRu ? 'Статистика' : 'Statistics';
  String get profile => isRu ? 'Профиль' : 'Profile';
  String get completeDay => isRu ? 'Завершить смену' : 'Complete shift';
  String get revenue => isRu ? 'Выручка' : 'Revenue';
  String get earnings => isRu ? 'Заработок' : 'Earnings';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get add => isRu ? 'Добавить' : 'Add';
}
