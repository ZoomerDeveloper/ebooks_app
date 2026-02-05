# 🚀 Быстрый старт Epoems

## Что уже сделано

Полностью рабочее Flutter приложение со всеми экранами из ТЗ:

✅ **Splash Screen** с анимацией  
✅ **Onboarding** (3 красивых экрана)  
✅ **Авторизация** (вход по паролю, вход по коду, регистрация)  
✅ **Главный экран** (каталог A-Z, поиск, список стихов)  
✅ **Экран стиха** (форматированный текст с токенами)  
✅ **Профиль** с информацией о подписке  
✅ **Статистика** с круговой диаграммой прогресса  
✅ **Избранное** с swipe-to-delete  
✅ **Premium** с информацией о подписке  

## 🎨 Современный дизайн

- Градиенты (Indigo → Purple → Pink)
- Google Fonts (Poppins, Inter, Crimson Text)
- Плавные анимации
- Material Design 3
- Красивые карточки и кнопки

## ⚙️ Перед запуском

### 1. Укажите URL вашего backend

Откройте файл [lib/constants/app_constants.dart](lib/constants/app_constants.dart) и замените:

```dart
static const String baseUrl = 'http://localhost:8000';
```

на URL вашего backend API (например, `https://api.epoems.ru`).

### 2. Установите зависимости (уже выполнено)

```bash
flutter pub get
```

## 🏃 Запуск приложения

### iOS Simulator
```bash
flutter run -d "iPhone 15 Pro"
```

### Android Emulator
```bash
flutter run -d emulator-5554
```

### Подключенное устройство
```bash
flutter devices          # Посмотреть список устройств
flutter run -d <device>  # Запустить на конкретном устройстве
```

## 📱 Тестирование функций

### 1. Гостевой режим (без регистрации)
- Запустите приложение
- Пройдите онбординг
- Используйте каталог и поиск
- Читайте бесплатные стихи

### 2. Регистрация
- Нажмите "Sign In" → "Sign Up"
- Введите email и пароль
- После успешной регистрации откроется главный экран

### 3. Вход по коду
- Нажмите "Sign In with Email Code"
- Введите email
- Получите код на почту (если backend настроен)
- Введите код для входа

### 4. Основные функции
- **Каталог**: выберите букву A-Z
- **Поиск**: введите слово в поиск
- **Стих**: нажмите на карточку → читайте стих с форматированием
- **Избранное**: в стихе нажмите ❤️ → перейдите в раздел Favorites
- **Статистика**: посмотрите прогресс обучения
- **Premium**: посмотрите информацию о подписке

## 🔧 Структура кода

```
lib/
├── constants/          # Цвета, стили, константы
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_constants.dart
├── models/            # Модели данных
│   ├── poem.dart
│   ├── user.dart
│   ├── subscription.dart
│   ├── stats.dart
│   └── app_config.dart
├── services/          # API и хранилище
│   ├── api_service.dart
│   └── storage_service.dart
├── providers/         # State management
│   ├── auth_provider.dart
│   ├── poem_provider.dart
│   └── app_data_provider.dart
├── screens/           # Экраны
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── poem_screen.dart
│   ├── profile_screen.dart
│   ├── stats_screen.dart
│   ├── subscription_screen.dart
│   ├── favorites_screen.dart
│   └── auth/
│       ├── login_screen.dart
│       ├── register_screen.dart
│       └── login_code_screen.dart
├── widgets/           # Переиспользуемые виджеты
│   ├── gradient_button.dart
│   ├── custom_text_field.dart
│   ├── poem_card.dart
│   └── common_widgets.dart
└── main.dart         # Точка входа
```

## 🎯 Навигация

Все роуты настроены в `main.dart`:

- `/` - Splash Screen
- `/onboarding` - Онбординг
- `/login` - Вход
- `/register` - Регистрация
- `/login-code` - Вход по коду
- `/home` - Главный экран
- `/poem` - Экран стиха (требует `arguments: poemId`)
- `/profile` - Профиль
- `/stats` - Статистика
- `/subscription` - Premium
- `/favorites` - Избранное

## 🔐 Хранилище

- **JWT токен**: `flutter_secure_storage` (безопасное хранение)
- **Флаг онбординга**: `shared_preferences`

## ⚡ Hot Reload

Flutter поддерживает горячую перезагрузку:
- В VS Code: `Cmd+S` (macOS) или `Ctrl+S` (Windows/Linux)
- В терминале: нажмите `r`

## 🐛 Отладка

### Посмотреть логи
```bash
flutter logs
```

### Очистить build
```bash
flutter clean
flutter pub get
flutter run
```

### Проблемы с градиентами на iOS?
Добавьте в Info.plist:
```xml
<key>io.flutter.embedded_views_preview</key>
<true/>
```

## 📊 Проверка ошибок

```bash
flutter analyze
```

## 🎨 Кастомизация

### Изменить цвета
Откройте [lib/constants/app_colors.dart](lib/constants/app_colors.dart)

### Изменить шрифты
Откройте [lib/constants/app_text_styles.dart](lib/constants/app_text_styles.dart)

### Добавить новый экран
1. Создайте файл в `lib/screens/`
2. Добавьте роут в `main.dart` → `onGenerateRoute`

## 🚀 Build для production

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## ✨ Готово!

Приложение полностью готово к использованию. Все экраны реализованы с современным дизайном и плавными анимациями.

**Наслаждайтесь разработкой! 🎉**
