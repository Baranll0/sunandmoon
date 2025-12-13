/// App Strings - Localization support for English and Turkish
/// English is the default language
class AppStrings {
  final String locale;

  AppStrings(this.locale);

  // Navigation & Screens
  String get journeyTitle => _getString('journeyTitle', en: 'Journey', tr: 'Yolculuk');
  String get chapter => _getString('chapter', en: 'Chapter', tr: 'Bölüm');
  String get level => _getString('level', en: 'Level', tr: 'Seviye');
  String get settings => _getString('settings', en: 'Settings', tr: 'Ayarlar');
  String get language => _getString('language', en: 'Language', tr: 'Dil');
  String get english => _getString('english', en: 'English', tr: 'İngilizce');
  String get turkish => _getString('turkish', en: 'Turkish', tr: 'Türkçe');

  // Loading & Errors
  String get loading => _getString('loading', en: 'Loading...', tr: 'Yükleniyor...');
  String get loadingError => _getString('loadingError', en: 'Loading Error', tr: 'Yükleme hatası');
  String get pleaseRetry => _getString('pleaseRetry', en: 'Please try again', tr: 'Lütfen tekrar deneyin');
  String get retry => _getString('retry', en: 'Retry', tr: 'Yeniden Dene');
  String get errorStartingLevel => _getString('errorStartingLevel', en: 'Error starting level', tr: 'Seviye başlatma hatası');

  // Game Menu
  String get menu => _getString('menu', en: 'Menu', tr: 'Menü');
  String get resume => _getString('resume', en: 'Resume', tr: 'Devam Et');
  String get restart => _getString('restart', en: 'Restart', tr: 'Yeniden Başla');
  String get exitToMap => _getString('exitToMap', en: 'Exit to Journey Map', tr: 'Yolculuğa Dön');
  String get exitApp => _getString('exitApp', en: 'Exit App?', tr: 'Oyundan Çık?');
  String get exitAppConfirm => _getString('exitAppConfirm', en: 'Are you sure you want to exit?', tr: 'Oyundan çıkmak istediğinize emin misiniz?');
  String get cancel => _getString('cancel', en: 'Cancel', tr: 'İptal');
  String get exit => _getString('exit', en: 'Exit', tr: 'Çık');

  // Victory Dialog
  String get puzzleSolved => _getString('puzzleSolved', en: 'Puzzle Solved!', tr: 'Bulmaca Çözüldü!');
  String get time => _getString('time', en: 'Time', tr: 'Süre');
  String get moves => _getString('moves', en: 'Moves', tr: 'Hamle');
  String get hints => _getString('hints', en: 'Hints', tr: 'İpucu');
  String get nextLevel => _getString('nextLevel', en: 'Next Level', tr: 'Sonraki Seviye');
  String get newGame => _getString('newGame', en: 'New Game', tr: 'Yeni Oyun');

  // Game Controls
  String get undo => _getString('undo', en: 'Undo', tr: 'Geri Al');
  String get redo => _getString('redo', en: 'Redo', tr: 'İleri Al');
  String get clear => _getString('clear', en: 'Clear', tr: 'Temizle');
  String get pencil => _getString('pencil', en: 'Pencil', tr: 'Not');
  String get hint => _getString('hint', en: 'Hint', tr: 'İpucu');
  String get noHintsAvailable => _getString('noHintsAvailable', en: 'No Hints Available', tr: 'İpucu Yok');
  String get comeBackTomorrow => _getString('comeBackTomorrow', en: 'Come back tomorrow!', tr: 'Yarın tekrar gel!');
  String get noteModeDescription => _getString('noteModeDescription', en: 'Note Mode: Tap to mark possibilities without errors.', tr: 'Not Modu: Hatalar olmadan olasılıkları işaretlemek için dokunun.');

  // Settings
  String get hapticFeedback => _getString('hapticFeedback', en: 'Haptic Feedback', tr: 'Dokunsal Geri Bildirim');
  String get hapticFeedbackSubtitle => _getString('hapticFeedbackSubtitle', en: 'Vibration feedback for interactions', tr: 'Etkileşimler için titreşim geri bildirimi');
  String get soundEffects => _getString('soundEffects', en: 'Sound Effects', tr: 'Ses Efektleri');
  String get soundEffectsEnabled => _getString('soundEffectsEnabled', en: 'Sounds are enabled', tr: 'Sesler açık');
  String get soundEffectsDisabled => _getString('soundEffectsDisabled', en: 'Sounds are muted', tr: 'Sesler kapalı');
  String get autoCheck => _getString('autoCheck', en: 'Auto-Check', tr: 'Otomatik Kontrol');
  String get autoCheckSubtitle => _getString('autoCheckSubtitle', en: 'Automatically highlight errors', tr: 'Hataları otomatik olarak vurgula');
  String get about => _getString('about', en: 'About', tr: 'Hakkında');
  String get appName => _getString('appName', en: 'Tango Logic', tr: 'Tango Logic');
  String get appSubtitle => _getString('appSubtitle', en: 'A Sun & Moon Puzzle', tr: 'Güneş & Ay Bulmacası');
  String get version => _getString('version', en: 'Version', tr: 'Sürüm');
  String get appDescription => _getString('appDescription', en: 'A relaxing logic puzzle game based on Takuzu/Binairo rules.', tr: 'Takuzu/Binairo kurallarına dayalı rahatlatıcı bir mantık bulmaca oyunu.');
  
  // How to Play
  String get howToPlay => _getString('howToPlay', en: 'How to Play', tr: 'Nasıl Oynanır');
  String get howToPlaySection => _getString('howToPlaySection', en: 'How to Play', tr: 'Nasıl Oynanır');
  
  // Rules
  String get ruleBalanceTitle => _getString('ruleBalanceTitle', en: 'Equal Balance', tr: 'Eşit Denge');
  String get ruleBalanceDescription => _getString('ruleBalanceDescription', en: 'Each row and column must have exactly half Suns and half Moons. In a 4x4 grid, that means 2 Suns and 2 Moons per row and column.', tr: 'Her satır ve sütunda tam olarak yarı yarıya Güneş ve Ay olmalı. 4x4 grid\'de bu, her satır ve sütunda 2 Güneş ve 2 Ay demektir.');
  
  String get ruleNoThreeTitle => _getString('ruleNoThreeTitle', en: 'No Three in a Row', tr: 'Üç Yan Yana Yok');
  String get ruleNoThreeDescription => _getString('ruleNoThreeDescription', en: 'You cannot have three of the same symbol (Sun or Moon) in a row horizontally or vertically. Maximum two consecutive.', tr: 'Aynı sembolden (Güneş veya Ay) üç tanesi yatay veya dikey olarak yan yana olamaz. Maksimum iki tane yan yana olabilir.');
  
  String get ruleUniqueTitle => _getString('ruleUniqueTitle', en: 'Unique Rows & Columns', tr: 'Benzersiz Satırlar ve Sütunlar');
  String get ruleUniqueDescription => _getString('ruleUniqueDescription', en: 'No two rows can be identical, and no two columns can be identical. Each row and column must be unique.', tr: 'İki satır aynı olamaz ve iki sütun aynı olamaz. Her satır ve sütun benzersiz olmalıdır.');
  
  // Steps
  String get step1Title => _getString('step1Title', en: 'Fill the Grid', tr: 'Grid\'i Doldurun');
  String get step1Description => _getString('step1Description', en: 'Tap empty cells to place Suns or Moons. Some cells are pre-filled as hints to help you get started.', tr: 'Boş hücrelere dokunarak Güneş veya Ay yerleştirin. Bazı hücreler ipucu olarak önceden doldurulmuştur.');
  
  String get step2Title => _getString('step2Title', en: 'Follow the Rules', tr: 'Kurallara Uyun');
  String get step2Description => _getString('step2Description', en: 'Make sure each row and column has equal Suns and Moons, no three in a row, and all rows/columns are unique.', tr: 'Her satır ve sütunda eşit Güneş ve Ay olduğundan, üç yan yana olmadığından ve tüm satır/sütunların benzersiz olduğundan emin olun.');
  
  String get step3Title => _getString('step3Title', en: 'Use Logic', tr: 'Mantık Kullanın');
  String get step3Description => _getString('step3Description', en: 'Look for patterns: if you see two Suns in a row, the next cell must be a Moon. If a row has 2 Suns and 2 empty cells, those must be Moons.', tr: 'Desenlere bakın: İki Güneş yan yana görürseniz, bir sonraki hücre Ay olmalı. Bir satırda 2 Güneş ve 2 boş hücre varsa, bunlar Ay olmalı.');
  
  String get step4Title => _getString('step4Title', en: 'Complete the Puzzle', tr: 'Bulmacayı Tamamlayın');
  String get step4Description => _getString('step4Description', en: 'When all cells are filled correctly according to all rules, the puzzle is solved! Use hints if you get stuck (5 hints per day).', tr: 'Tüm hücreler tüm kurallara göre doğru şekilde doldurulduğunda, bulmaca çözülmüştür! Takılırsanız ipucu kullanın (günde 5 ipucu).');
  
  // Advanced Logic Section
  String get advancedLogicTitle => _getString('advancedLogicTitle', en: 'Advanced Logic', tr: 'İleri Seviye Mantık');
  String get advancedLogicDescription => _getString('advancedLogicDescription', en: 'Not all puzzles can be solved by immediate forced moves. Some placements may seem valid at first, but only deeper logical deduction reveals the correct path. This is where true reasoning begins.', tr: 'Tüm bulmacalar anında zorunlu hamlelerle çözülemez. Bazı yerleştirmeler ilk bakışta geçerli görünebilir, ancak sadece daha derin mantıksal çıkarım doğru yolu ortaya çıkarır. İşte gerçek mantık burada başlar.');
  String get advancedLogicTip1 => _getString('advancedLogicTip1', en: 'Sometimes multiple placements seem possible. Test each hypothesis mentally before committing.', tr: 'Bazen birden fazla yerleştirme mümkün görünebilir. Karar vermeden önce her hipotezi zihinsel olarak test edin.');
  String get advancedLogicTip2 => _getString('advancedLogicTip2', en: 'Chain deductions together. One placement may unlock several others.', tr: 'Çıkarımları birbirine bağlayın. Bir yerleştirme birkaç başkasını açabilir.');
  String get advancedLogicTip3 => _getString('advancedLogicTip3', en: 'If you reach a contradiction, backtrack and reconsider earlier assumptions.', tr: 'Bir çelişkiye ulaşırsanız, geri dönün ve önceki varsayımları yeniden değerlendirin.');
  
  // Chapter Difficulty Labels
  String get chapterDifficultyBeginner => _getString('chapterDifficultyBeginner', en: 'Beginner Logic', tr: 'Başlangıç Seviyesi');
  String get chapterDifficultyIntermediate => _getString('chapterDifficultyIntermediate', en: 'Intermediate Logic', tr: 'Orta Seviye');
  String get chapterDifficultyAdvanced => _getString('chapterDifficultyAdvanced', en: 'Advanced Logic', tr: 'İleri Seviye');
  String get chapterDifficultyExpert => _getString('chapterDifficultyExpert', en: 'Expert Logic', tr: 'Uzman Seviyesi');
  String get chapterDifficultyDescription1 => _getString('chapterDifficultyDescription1', en: 'Learn the fundamentals', tr: 'Temelleri öğrenin');
  String get chapterDifficultyDescription2 => _getString('chapterDifficultyDescription2', en: 'Larger grids require deeper reasoning', tr: 'Daha büyük gridler daha derin mantık gerektirir');
  String get chapterDifficultyDescription3 => _getString('chapterDifficultyDescription3', en: 'Some puzzles require branching logic', tr: 'Bazı bulmacalar dallanma mantığı gerektirir');
  String get chapterDifficultyDescription4 => _getString('chapterDifficultyDescription4', en: 'Master-level challenges', tr: 'Ustası seviyesi zorluklar');
  
  // Steps (instead of Moves)
  String get steps => _getString('steps', en: 'Steps', tr: 'Adım');
  String get stepsLabel => _getString('stepsLabel', en: 'Steps', tr: 'Adımlar');
  
  // Hint System Improvements
  String get hintsWillRefresh => _getString('hintsWillRefresh', en: 'Hints will refresh soon', tr: 'İpuçları yakında yenilenecek');
  String get hintsRefreshTime => _getString('hintsRefreshTime', en: 'Next hint available in', tr: 'Sonraki ipucu');
  String get hintExplanation => _getString('hintExplanation', en: 'This move is forced because:', tr: 'Bu hamle zorunludur çünkü:');
  String get unlimitedHintsEarly => _getString('unlimitedHintsEarly', en: 'Unlimited hints in early chapters', tr: 'İlk bölümlerde sınırsız ipucu');

  // Empty States
  String get noPuzzleLoaded => _getString('noPuzzleLoaded', en: 'No puzzle loaded', tr: 'Yüklenen bulmaca yok');
  String get startNewGame => _getString('startNewGame', en: 'Start a new game to begin', tr: 'Başlamak için yeni bir oyun başlatın');

  // Helper method to get localized string
  String _getString(String key, {required String en, required String tr}) {
    return locale == 'tr' ? tr : en;
  }
}

