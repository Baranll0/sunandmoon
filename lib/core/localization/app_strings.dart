/// App Strings - Localization support for English, Turkish, German, and French
/// English is the default language
class AppStrings {
  final String locale;

  AppStrings(this.locale);

  // Navigation & Screens
  String get journeyTitle => _getString('journeyTitle', en: 'Journey', tr: 'Yolculuk', de: 'Reise', fr: 'Voyage');
  String get chapter => _getString('chapter', en: 'Chapter', tr: 'Bölüm', de: 'Kapitel', fr: 'Chapitre');
  String get level => _getString('level', en: 'Level', tr: 'Seviye', de: 'Stufe', fr: 'Niveau');
  String get settings => _getString('settings', en: 'Settings', tr: 'Ayarlar', de: 'Einstellungen', fr: 'Paramètres');
  String get language => _getString('language', en: 'Language', tr: 'Dil', de: 'Sprache', fr: 'Langue');
  String get english => _getString('english', en: 'English', tr: 'İngilizce', de: 'Englisch', fr: 'Anglais');
  String get turkish => _getString('turkish', en: 'Turkish', tr: 'Türkçe', de: 'Türkisch', fr: 'Turc');
  String get german => _getString('german', en: 'German', tr: 'Almanca', de: 'Deutsch', fr: 'Allemand');
  String get french => _getString('french', en: 'French', tr: 'Fransızca', de: 'Französisch', fr: 'Français');
  String get home => _getString('home', en: 'Home', tr: 'Ana Sayfa', de: 'Startseite', fr: 'Accueil');
  String get startJourney => _getString('startJourney', en: 'Start Journey', tr: 'Yolculuğa Başla', de: 'Reise beginnen', fr: 'Commencer le voyage');
  String get locked => _getString('locked', en: 'Locked', tr: 'Kilitli', de: 'Gesperrt', fr: 'Verrouillé');
  String get completeLevelFirst => _getString('completeLevelFirst', en: 'Complete the previous level first', tr: 'Önce önceki seviyeyi tamamlayın', de: 'Vervollständige zuerst das vorherige Level', fr: 'Complétez d\'abord le niveau précédent');

  // Loading & Errors
  String get loading => _getString('loading', en: 'Loading...', tr: 'Yükleniyor...', de: 'Laden...', fr: 'Chargement...');
  String get loadingError => _getString('loadingError', en: 'Loading Error', tr: 'Yükleme hatası', de: 'Ladefehler', fr: 'Erreur de chargement');
  String get pleaseRetry => _getString('pleaseRetry', en: 'Please try again', tr: 'Lütfen tekrar deneyin', de: 'Bitte versuchen Sie es erneut', fr: 'Veuillez réessayer');
  String get retry => _getString('retry', en: 'Retry', tr: 'Yeniden Dene', de: 'Wiederholen', fr: 'Réessayer');
  String get errorStartingLevel => _getString('errorStartingLevel', en: 'Error starting level', tr: 'Seviye başlatma hatası', de: 'Fehler beim Starten des Levels', fr: 'Erreur lors du démarrage du niveau');

  // Game Menu
  String get menu => _getString('menu', en: 'Menu', tr: 'Menü', de: 'Menü', fr: 'Menu');
  String get resume => _getString('resume', en: 'Resume', tr: 'Devam Et', de: 'Fortsetzen', fr: 'Reprendre');
  String get restart => _getString('restart', en: 'Restart', tr: 'Yeniden Başla', de: 'Neustart', fr: 'Redémarrer');
  String get exitToMap => _getString('exitToMap', en: 'Exit to Journey Map', tr: 'Yolculuğa Dön', de: 'Zur Karte zurückkehren', fr: 'Retour à la carte');
  String get exitApp => _getString('exitApp', en: 'Exit App?', tr: 'Oyundan Çık?', de: 'App beenden?', fr: 'Quitter l\'application ?');
  String get exitAppConfirm => _getString('exitAppConfirm', en: 'Are you sure you want to exit?', tr: 'Oyundan çıkmak istediğinize emin misiniz?', de: 'Sind Sie sicher, dass Sie beenden möchten?', fr: 'Êtes-vous sûr de vouloir quitter ?');
  String get cancel => _getString('cancel', en: 'Cancel', tr: 'İptal', de: 'Abbrechen', fr: 'Annuler');
  String get exit => _getString('exit', en: 'Exit', tr: 'Çık', de: 'Beenden', fr: 'Quitter');

  // Victory Dialog
  String get puzzleSolved => _getString('puzzleSolved', en: 'Puzzle Solved!', tr: 'Bulmaca Çözüldü!', de: 'Rätsel gelöst!', fr: 'Puzzle résolu !');
  String get time => _getString('time', en: 'Time', tr: 'Süre', de: 'Zeit', fr: 'Temps');
  String get moves => _getString('moves', en: 'Moves', tr: 'Hamle', de: 'Züge', fr: 'Mouvements');
  String get hints => _getString('hints', en: 'Hints', tr: 'İpucu', de: 'Hinweise', fr: 'Indices');
  String get nextLevel => _getString('nextLevel', en: 'Next Level', tr: 'Sonraki Seviye', de: 'Nächstes Level', fr: 'Niveau suivant');
  String get newGame => _getString('newGame', en: 'New Game', tr: 'Yeni Oyun', de: 'Neues Spiel', fr: 'Nouveau jeu');
  String get backToMap => _getString('backToMap', en: 'Back to Map', tr: 'Haritaya Dön', de: 'Zur Karte', fr: 'Retour à la carte');
  String get replay => _getString('replay', en: 'Replay', tr: 'Tekrar Oyna', de: 'Wiederholen', fr: 'Rejouer');

  // Game Controls
  String get undo => _getString('undo', en: 'Undo', tr: 'Geri Al', de: 'Rückgängig', fr: 'Annuler');
  String get redo => _getString('redo', en: 'Redo', tr: 'İleri Al', de: 'Wiederholen', fr: 'Refaire');
  String get clear => _getString('clear', en: 'Clear', tr: 'Temizle', de: 'Löschen', fr: 'Effacer');
  String get pencil => _getString('pencil', en: 'Pencil', tr: 'Not', de: 'Notiz', fr: 'Crayon');
  String get hint => _getString('hint', en: 'Hint', tr: 'İpucu', de: 'Hinweis', fr: 'Indice');
  String get sun => _getString('sun', en: 'Sun', tr: 'Güneş', de: 'Sonne', fr: 'Soleil');
  String get moon => _getString('moon', en: 'Moon', tr: 'Ay', de: 'Mond', fr: 'Lune');
  String get erase => _getString('erase', en: 'Erase', tr: 'Sil', de: 'Löschen', fr: 'Effacer');
  String get noHintsAvailable => _getString('noHintsAvailable', en: 'No Hints Available', tr: 'İpucu Yok', de: 'Keine Hinweise verfügbar', fr: 'Aucun indice disponible');
  String get comeBackTomorrow => _getString('comeBackTomorrow', en: 'Come back tomorrow!', tr: 'Yarın tekrar gel!', de: 'Kommen Sie morgen wieder!', fr: 'Revenez demain !');
  String get noteModeDescription => _getString('noteModeDescription', en: 'Note Mode: Tap to mark possibilities without errors.', tr: 'Not Modu: Hatalar olmadan olasılıkları işaretlemek için dokunun.', de: 'Notizmodus: Tippen Sie, um Möglichkeiten ohne Fehler zu markieren.', fr: 'Mode note : Appuyez pour marquer les possibilités sans erreurs.');

  // Settings
  String get hapticFeedback => _getString('hapticFeedback', en: 'Haptic Feedback', tr: 'Dokunsal Geri Bildirim', de: 'Haptisches Feedback', fr: 'Retour haptique');
  String get hapticFeedbackSubtitle => _getString('hapticFeedbackSubtitle', en: 'Vibration feedback for interactions', tr: 'Etkileşimler için titreşim geri bildirimi', de: 'Vibrationsfeedback für Interaktionen', fr: 'Retour de vibration pour les interactions');
  String get soundEffects => _getString('soundEffects', en: 'Sound Effects', tr: 'Ses Efektleri', de: 'Soundeffekte', fr: 'Effets sonores');
  String get soundEffectsEnabled => _getString('soundEffectsEnabled', en: 'Sounds are enabled', tr: 'Sesler açık', de: 'Sounds sind aktiviert', fr: 'Les sons sont activés');
  String get soundEffectsDisabled => _getString('soundEffectsDisabled', en: 'Sounds are muted', tr: 'Sesler kapalı', de: 'Sounds sind stummgeschaltet', fr: 'Les sons sont désactivés');
  String get autoCheck => _getString('autoCheck', en: 'Auto-Check', tr: 'Otomatik Kontrol', de: 'Automatische Prüfung', fr: 'Vérification automatique');
  String get autoCheckSubtitle => _getString('autoCheckSubtitle', en: 'Automatically highlight errors', tr: 'Hataları otomatik olarak vurgula', de: 'Fehler automatisch hervorheben', fr: 'Mettre en évidence automatiquement les erreurs');
  String get about => _getString('about', en: 'About', tr: 'Hakkında', de: 'Über', fr: 'À propos');
  String get appName => _getString('appName', en: 'Tango Logic', tr: 'Tango Logic', de: 'Tango Logic', fr: 'Tango Logic');
  String get appSubtitle => _getString('appSubtitle', en: 'A Sun & Moon Puzzle', tr: 'Güneş & Ay Bulmacası', de: 'Ein Sonne & Mond Puzzle', fr: 'Un puzzle Soleil & Lune');
  String get version => _getString('version', en: 'Version', tr: 'Sürüm', de: 'Version', fr: 'Version');
  String get appDescription => _getString('appDescription', en: 'A relaxing logic puzzle game based on Takuzu/Binairo rules.', tr: 'Takuzu/Binairo kurallarına dayalı rahatlatıcı bir mantık bulmaca oyunu.', de: 'Ein entspannendes Logik-Puzzle-Spiel basierend auf Takuzu/Binairo-Regeln.', fr: 'Un jeu de puzzle logique relaxant basé sur les règles Takuzu/Binairo.');
  
  // How to Play
  String get help => _getString('help', en: 'Help', tr: 'Yardım');
  String get howToPlay => _getString('howToPlay', en: 'How to Play', tr: 'Nasıl Oynanır');
  String get howToPlaySection => _getString('howToPlaySection', en: 'How to Play', tr: 'Nasıl Oynanır');
  String get reportBug => _getString('reportBug', en: 'Report Bug', tr: 'Hata Bildir');

  String get rule1 => _getString('rule1', en: 'Each row and column needs an equal number of Sun and Moon cells.', tr: 'Her satır ve sütunda eşit sayıda Güneş ve Ay bulunmalıdır.');
  String get rule2 => _getString('rule2', en: 'No more than two of the same symbol can be next to each other.', tr: 'Aynı sembolden ikiden fazlası yan yana gelemez.');
  String get rule3 => _getString('rule3', en: 'All rows and columns must be unique.', tr: 'Tüm satırlar ve sütunlar benzersiz olmalıdır.');
  
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
  String get chapterDifficultyBeginner => _getString('chapterDifficultyBeginner', en: 'Beginner Logic', tr: 'Başlangıç Seviyesi', de: 'Anfängerlogik', fr: 'Logique débutant');
  String get chapterDifficultyIntermediate => _getString('chapterDifficultyIntermediate', en: 'Intermediate Logic', tr: 'Orta Seviye', de: 'Mittlere Logik', fr: 'Logique intermédiaire');
  String get chapterDifficultyAdvanced => _getString('chapterDifficultyAdvanced', en: 'Advanced Logic', tr: 'İleri Seviye', de: 'Fortgeschrittene Logik', fr: 'Logique avancée');
  String get chapterDifficultyExpert => _getString('chapterDifficultyExpert', en: 'Expert Logic', tr: 'Uzman Seviyesi', de: 'Expertenlogik', fr: 'Logique experte');
  String get chapterDifficultyDescription1 => _getString('chapterDifficultyDescription1', en: 'Learn the fundamentals', tr: 'Temelleri öğrenin', de: 'Grundlagen lernen', fr: 'Apprendre les fondamentaux');
  String get chapterDifficultyDescription2 => _getString('chapterDifficultyDescription2', en: 'Larger grids require deeper reasoning', tr: 'Daha büyük gridler daha derin mantık gerektirir', de: 'Größere Raster erfordern tiefere Überlegungen', fr: 'Les grilles plus grandes nécessitent un raisonnement plus approfondi');
  String get chapterDifficultyDescription3 => _getString('chapterDifficultyDescription3', en: 'Some puzzles require branching logic', tr: 'Bazı bulmacalar dallanma mantığı gerektirir', de: 'Einige Rätsel erfordern verzweigte Logik', fr: 'Certains puzzles nécessitent une logique de branchement');
  String get chapterDifficultyDescription4 => _getString('chapterDifficultyDescription4', en: 'Master-level challenges', tr: 'Ustası seviyesi zorluklar', de: 'Herausforderungen auf Meisterniveau', fr: 'Défis de niveau maître');
  
  // Steps (instead of Moves)
  String get steps => _getString('steps', en: 'Steps', tr: 'Adım', de: 'Schritte', fr: 'Étapes');
  String get stepsLabel => _getString('stepsLabel', en: 'Steps', tr: 'Adımlar', de: 'Schritte', fr: 'Étapes');
  String get mistakes => _getString('mistakes', en: 'Mistakes', tr: 'Hatalar', de: 'Fehler', fr: 'Erreurs');
  String get pause => _getString('pause', en: 'Pause', tr: 'Duraklat', de: 'Pause', fr: 'Pause');
  
  // Hint System Improvements
  String get hintsWillRefresh => _getString('hintsWillRefresh', en: 'Hints will refresh soon', tr: 'İpuçları yakında yenilenecek');
  String get hintsRefreshTime => _getString('hintsRefreshTime', en: 'Next hint available in', tr: 'Sonraki ipucu');
  String get hintExplanation => _getString('hintExplanation', en: 'This move is forced because:', tr: 'Bu hamle zorunludur çünkü:');
  String get unlimitedHintsEarly => _getString('unlimitedHintsEarly', en: 'Unlimited hints in early chapters', tr: 'İlk bölümlerde sınırsız ipucu');

  // Empty States
  String get noPuzzleLoaded => _getString('noPuzzleLoaded', en: 'No puzzle loaded', tr: 'Yüklenen bulmaca yok', de: 'Kein Puzzle geladen', fr: 'Aucun puzzle chargé');
  String get startNewGame => _getString('startNewGame', en: 'Start a new game to begin', tr: 'Başlamak için yeni bir oyun başlatın', de: 'Starten Sie ein neues Spiel, um zu beginnen', fr: 'Démarrez un nouveau jeu pour commencer');

  // Level Selection Dialog
  String get selectLevel => _getString('selectLevel', en: 'Select Level', tr: 'Seviye Seç', de: 'Stufe auswählen', fr: 'Sélectionner le niveau');
  String get start => _getString('start', en: 'Start', tr: 'Başla', de: 'Starten', fr: 'Démarrer');
  String get gridSize => _getString('gridSize', en: 'Grid Size', tr: 'Grid Boyutu', de: 'Rastergröße', fr: 'Taille de la grille');

  // Pencil Mode
  String get pencilMode => _getString('pencilMode', en: 'Pencil Mode', tr: 'Not Modu', de: 'Notizmodus', fr: 'Mode crayon');
  String get pencilModeTip1 => _getString('pencilModeTip1', en: '1. Tap the Pencil button to activate Pencil Mode', tr: '1. Not Modunu etkinleştirmek için Not butonuna dokunun', de: '1. Tippen Sie auf die Notiz-Schaltfläche, um den Notizmodus zu aktivieren', fr: '1. Appuyez sur le bouton Crayon pour activer le mode crayon');
  String get pencilModeTip2 => _getString('pencilModeTip2', en: '2. Tap an empty cell to add/remove pencil marks', tr: '2. Not işaretleri eklemek/çıkarmak için boş bir hücreye dokunun', de: '2. Tippen Sie auf eine leere Zelle, um Notizen hinzuzufügen/zu entfernen', fr: '2. Appuyez sur une cellule vide pour ajouter/retirer des marques de crayon');
  String get pencilModeTip3 => _getString('pencilModeTip3', en: '3. Pencil marks help you track possible values', tr: '3. Not işaretleri olası değerleri takip etmenize yardımcı olur', de: '3. Notizen helfen Ihnen, mögliche Werte zu verfolgen', fr: '3. Les marques de crayon vous aident à suivre les valeurs possibles');
  String get pencilModeTip4 => _getString('pencilModeTip4', en: '4. Tap the Pencil button again to deactivate', tr: '4. Devre dışı bırakmak için Not butonuna tekrar dokunun', de: '4. Tippen Sie erneut auf die Notiz-Schaltfläche, um zu deaktivieren', fr: '4. Appuyez à nouveau sur le bouton Crayon pour désactiver');
  String get gotIt => _getString('gotIt', en: 'Got it', tr: 'Anladım', de: 'Verstanden', fr: 'Compris');
  String get pencilModeDescription => _getString('pencilModeDescription', en: 'Pencil Mode allows you to mark possible values in empty cells without committing to them.', tr: 'Not Modu, boş hücrelerde olası değerleri taahhüt etmeden işaretlemenize olanak tanır.', de: 'Der Notizmodus ermöglicht es Ihnen, mögliche Werte in leeren Zellen zu markieren, ohne sich festzulegen.', fr: 'Le mode crayon vous permet de marquer les valeurs possibles dans les cellules vides sans vous engager.');
  String get howToUse => _getString('howToUse', en: 'How to use:', tr: 'Nasıl kullanılır:', de: 'Wie man es benutzt:', fr: 'Comment utiliser :');
  String get pencilModeTip => _getString('pencilModeTip', en: 'Tip: Use pencil marks to work through logic without making permanent moves.', tr: 'İpucu: Kalıcı hamleler yapmadan mantık üzerinden çalışmak için not işaretlerini kullanın.', de: 'Tipp: Verwenden Sie Notizen, um durch Logik zu arbeiten, ohne permanente Züge zu machen.', fr: 'Astuce : Utilisez les marques de crayon pour travailler la logique sans faire de mouvements permanents.');

  // Errors
  String get signInFailed => _getString('signInFailed', en: 'Sign in failed', tr: 'Giriş başarısız', de: 'Anmeldung fehlgeschlagen', fr: 'Échec de la connexion');
  String get errorStartingGame => _getString('errorStartingGame', en: 'Error starting game', tr: 'Oyun başlatma hatası', de: 'Fehler beim Starten des Spiels', fr: 'Erreur lors du démarrage du jeu');
  String get statisticsComingSoon => _getString('statisticsComingSoon', en: 'Statistics Screen - Coming Soon', tr: 'İstatistikler Ekranı - Yakında', de: 'Statistikbildschirm - Kommt bald', fr: 'Écran des statistiques - Bientôt disponible');

  // Login Screen
  String get signingIn => _getString('signingIn', en: 'Signing in...', tr: 'Giriş yapılıyor...', de: 'Anmeldung läuft...', fr: 'Connexion en cours...');
  String get continueWithGoogle => _getString('continueWithGoogle', en: 'Continue with Google', tr: 'Google ile Devam Et', de: 'Mit Google fortfahren', fr: 'Continuer avec Google');
  String get signInToSaveProgress => _getString('signInToSaveProgress', en: 'Sign in to save your progress across devices', tr: 'Cihazlar arasında ilerlemenizi kaydetmek için giriş yapın', de: 'Melden Sie sich an, um Ihren Fortschritt geräteübergreifend zu speichern', fr: 'Connectez-vous pour sauvegarder votre progression sur tous les appareils');

  // Mechanics
  String get mechanicClassicTitle => _getString('mechanicClassicTitle', en: 'Classic', tr: 'Klasik', de: 'Klassisch', fr: 'Classique');
  String get mechanicClassicDescription => _getString('mechanicClassicDescription', en: 'Standard puzzle rules', tr: 'Standart bulmaca kuralları', de: 'Standard-Puzzle-Regeln', fr: 'Règles de puzzle standard');
  
  String get mechanicRegionsTitle => _getString('mechanicRegionsTitle', en: 'Regions', tr: 'Bölgeler', de: 'Regionen', fr: 'Régions');
  String get mechanicRegionsDescription => _getString('mechanicRegionsDescription', en: 'Board divided into regions with equal Sun/Moon balance', tr: 'Tahta eşit Güneş/Ay dengesi olan bölgelere ayrılmış', de: 'Brett in Regionen mit gleichem Sonnen-/Mondgleichgewicht unterteilt', fr: 'Plateau divisé en régions avec équilibre égal Soleil/Lune');
  
  String get mechanicLockedCellsTitle => _getString('mechanicLockedCellsTitle', en: 'Locked Cells', tr: 'Kilitli Hücreler', de: 'Gesperrte Zellen', fr: 'Cellules verrouillées');
  String get mechanicLockedCellsDescription => _getString('mechanicLockedCellsDescription', en: 'Additional fixed cells that cannot be changed', tr: 'Değiştirilemeyen ek sabit hücreler', de: 'Zusätzliche feste Zellen, die nicht geändert werden können', fr: 'Cellules fixes supplémentaires qui ne peuvent pas être modifiées');
  
  String get mechanicAdvancedNoThreeTitle => _getString('mechanicAdvancedNoThreeTitle', en: 'Advanced Patterns', tr: 'İleri Seviye Desenler', de: 'Fortgeschrittene Muster', fr: 'Motifs avancés');
  String get mechanicAdvancedNoThreeDescription => _getString('mechanicAdvancedNoThreeDescription', en: 'Additional pattern restrictions beyond basic rules', tr: 'Temel kuralların ötesinde ek desen kısıtlamaları', de: 'Zusätzliche Musterbeschränkungen über die Grundregeln hinaus', fr: 'Restrictions de motifs supplémentaires au-delà des règles de base');
  
  String get mechanicHiddenRuleTitle => _getString('mechanicHiddenRuleTitle', en: 'Hidden Rule', tr: 'Gizli Kural', de: 'Versteckte Regel', fr: 'Règle cachée');
  String get mechanicHiddenRuleDescription => _getString('mechanicHiddenRuleDescription', en: 'A rule revealed after mistakes or via tutorial', tr: 'Hatalardan sonra veya öğretici ile ortaya çıkan bir kural', de: 'Eine Regel, die nach Fehlern oder über ein Tutorial enthüllt wird', fr: 'Une règle révélée après des erreurs ou via un tutoriel');
  
  String get mechanicMoveLimitTitle => _getString('mechanicMoveLimitTitle', en: 'Move Limit', tr: 'Hamle Limiti', de: 'Zuglimit', fr: 'Limite de mouvements');
  String get mechanicMoveLimitDescription => _getString('mechanicMoveLimitDescription', en: 'Maximum number of moves allowed', tr: 'İzin verilen maksimum hamle sayısı', de: 'Maximale Anzahl erlaubter Züge', fr: 'Nombre maximum de mouvements autorisés');
  
  String get mechanicMistakeLimitTitle => _getString('mechanicMistakeLimitTitle', en: 'Mistake Limit', tr: 'Hata Limiti', de: 'Fehlerlimit', fr: 'Limite d\'erreurs');
  String get mechanicMistakeLimitDescription => _getString('mechanicMistakeLimitDescription', en: 'Maximum number of invalid attempts allowed', tr: 'İzin verilen maksimum geçersiz deneme sayısı', de: 'Maximale Anzahl erlaubter ungültiger Versuche', fr: 'Nombre maximum de tentatives invalides autorisées');
  
  String get mechanicNoteRequiredTitle => _getString('mechanicNoteRequiredTitle', en: 'Notes Required', tr: 'Notlar Gerekli', de: 'Notizen erforderlich', fr: 'Notes requises');
  String get mechanicNoteRequiredDescription => _getString('mechanicNoteRequiredDescription', en: 'Pencil mode usage is required or suggested', tr: 'Not modu kullanımı gerekli veya önerilir', de: 'Bleistiftmodus ist erforderlich oder wird empfohlen', fr: 'L\'utilisation du mode crayon est requise ou suggérée');
  
  String get mechanicLimitedHintsTitle => _getString('mechanicLimitedHintsTitle', en: 'Limited Hints', tr: 'Sınırlı İpuçları', de: 'Begrenzte Hinweise', fr: 'Indices limités');
  String get mechanicLimitedHintsDescription => _getString('mechanicLimitedHintsDescription', en: 'Daily or per-level hint cap', tr: 'Günlük veya seviye başına ipucu limiti', de: 'Tägliche oder pro-Level-Hinweisgrenze', fr: 'Limite d\'indices quotidienne ou par niveau');
  
  String get mechanicChallengeModeTitle => _getString('mechanicChallengeModeTitle', en: 'Challenge Mode', tr: 'Meydan Okuma Modu', de: 'Herausforderungsmodus', fr: 'Mode défi');
  String get mechanicChallengeModeDescription => _getString('mechanicChallengeModeDescription', en: 'Special challenge with unique constraints', tr: 'Benzersiz kısıtlamalarla özel meydan okuma', de: 'Besondere Herausforderung mit einzigartigen Einschränkungen', fr: 'Défi spécial avec des contraintes uniques');
  
  // Mechanics enforcement messages
  String get outOfMoves => _getString('outOfMoves', en: 'Out of Moves', tr: 'Hamle Bitti', de: 'Keine Züge mehr', fr: 'Plus de mouvements');
  String get outOfMovesMessage => _getString('outOfMovesMessage', en: 'You have used all {maxMoves} moves. Try again or watch an ad for extra moves.', tr: 'Tüm {maxMoves} hamleyi kullandınız. Tekrar deneyin veya ekstra hamle için reklam izleyin.', de: 'Sie haben alle {maxMoves} Züge verwendet. Versuchen Sie es erneut oder schauen Sie eine Werbung für zusätzliche Züge.', fr: 'Vous avez utilisé tous les {maxMoves} mouvements. Réessayez ou regardez une publicité pour des mouvements supplémentaires.');
  String get levelFailed => _getString('levelFailed', en: 'Level Failed', tr: 'Seviye Başarısız', de: 'Level fehlgeschlagen', fr: 'Niveau échoué');
  String get levelFailedMessage => _getString('levelFailedMessage', en: 'You have failed this level. Try again!', tr: 'Bu seviyeyi geçemediniz. Tekrar deneyin!', de: 'Sie haben dieses Level nicht bestanden. Versuchen Sie es erneut!', fr: 'Vous avez échoué à ce niveau. Réessayez!');
  String get mistakeLimitExceeded => _getString('mistakeLimitExceeded', en: 'You have made {maxMistakes} mistakes. Level failed!', tr: '{maxMistakes} hata yaptınız. Seviye başarısız!', de: 'Sie haben {maxMistakes} Fehler gemacht. Level fehlgeschlagen!', fr: 'Vous avez fait {maxMistakes} erreurs. Niveau échoué!');

  // Helper method to get localized string
  String _getString(String key, {
    required String en,
    required String tr,
    String? de,
    String? fr,
  }) {
    switch (locale) {
      case 'tr':
        return tr;
      case 'de':
        return de ?? en; // Fallback to English if German translation missing
      case 'fr':
        return fr ?? en; // Fallback to English if French translation missing
      default:
        return en; // Default to English
    }
  }
}

