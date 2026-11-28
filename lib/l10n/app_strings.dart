// 5.1 Chuỗi giao diện.
// Vietnamese UI strings for new or modified screens (ADR-0005). Untouched screens keep their
// strings inline until they are edited.

/// Vietnamese UI strings. Interpolated text uses small functions.
class AppStrings {
  AppStrings._();

  // ---------- Common ----------
  static const String appName = 'DisGret';

  // ---------- Hôm nay, Farmly style (spec 017) ----------
  static const String shortcuts = 'Lối tắt';

  // ---------- Hold to start (spec 018) ----------
  static const String holdReady = 'Sẵn sàng chưa?';
  static const String holdToStartHint = 'Giữ nút để bắt đầu';
  static const String holdLonger = 'Giữ lâu hơn một chút nhé';
  static const String holdTop = 'Giữ để';
  static const String holdMore = 'Học thêm';
  static const List<String> holdLines = ['Gret đang khởi động…', 'Hít một hơi…', 'Vào biển!'];
  static const String holdSemantics = 'Giữ nút để bắt đầu học. Chạm hai lần để bắt đầu ngay.';
  static const String shortcutMap = 'Bản đồ';
  static const String shortcutCorner = 'Góc Gret';
  static const String shortcutReminders = 'Nhắc giờ';
  static const String shortcutProgress = 'Tiến độ';
  static const String todayTasks = 'Việc hôm nay';
  static String todayTasksDone(int done, int total) => '$done/$total đã xong';
  static String todayTaskLine(String habit, int minutes) => '$habit · $minutes phút';

  /// Launch screen under "DisGret" while the app opens (spec 011).
  static const String launchLine = 'Đang lặn xuống biển…';
  static const String settings = 'Cài đặt';
  static const String close = 'Đóng';
  static const String save = 'Lưu';
  static const String back = 'Quay lại';
  static const String cancel = 'Hủy';
  static const String backToToday = 'Về Hôm nay';

  // ---------- Tabs (5.1) ----------
  static const String tabToday = 'Hôm nay';
  static const String tabHabits = 'Thói quen';
  static const String tabProgress = 'Tiến độ';

  // ---------- Hôm nay ----------
  static const String todayGoalLabel = 'Mục tiêu hôm nay';
  static const String nextHabitLabel = 'Học tiếp';
  static const String start = 'Bắt đầu';
  static const String changePlan = 'Đổi thói quen hoặc thời lượng';
  static const String noHabitTitle = 'Chưa có thói quen nào';
  static const String noHabitMessage = 'Thêm một thói quen để biết hôm nay cần học gì.';
  static const String addHabit = 'Thêm thói quen';
  static const String allDoneTitle = 'Hôm nay bạn đã xong hết!';
  static const String allDoneMessage = 'Muốn học thêm thì vẫn có thể bắt đầu một phiên nữa.';
  static const String restDayTitle = 'Hôm nay là ngày nghỉ theo lịch';
  static const String restDayMessage = 'Nghỉ cũng được. Muốn học thì vẫn có thể bắt đầu một phiên.';
  static const String extraSession = 'Học thêm một phiên';
  static String identity(String identity) => 'Tôi là người $identity';
  static String minutes(int n) => '$n phút';
  static String demoHint(int seconds) => 'Chế độ demo: 1 phút chỉ dài $seconds giây';

  // ---------- 5.1 Tên gọi (spec 007) ----------
  static const String nameQuestion = 'Bạn muốn Gret gọi bạn là gì?';
  static const String nameLabel = 'Tên gọi';
  static const String nameHint = 'Biệt danh cũng được, để trống cũng không sao';
  static const String nameNotSet = 'Chưa đặt';
  static const String namePrivacy = 'Chỉ lưu trên máy này, để Gret chào bạn.';

  // ---------- 5.7 Hướng dẫn lần đầu (spec 022) ----------
  static const String tourSkip = 'Bỏ qua';
  static const String tourNext = 'Tiếp nhé';
  static const String tourBack = 'Lùi lại';
  static const String tourDone = 'Bắt đầu thôi!';
  static String tourProgress(int step, int total) => '$step/$total';
  static const String tourReplay = 'Xem lại hướng dẫn';
  static const String tourReplaySubtitle = 'Gret chỉ lại từng phần của màn Hôm nay';
  static const String tourSeaTitle = 'Đây là biển của bạn 🌊';
  static const String tourSeaBody =
      'Mỗi phút bạn học, nước lại trong hơn và cá bơi về đông vui. Lướt mạng xã hội lâu là biển '
      'đục đi đó!';
  static const String tourClarityTitle = 'Độ trong và chuỗi ngày';
  static const String tourClarityBody =
      'Hai thẻ này cho biết biển trong cỡ nào và bạn đã giữ thói quen bao nhiêu ngày liền.';
  static const String tourTasksTitle = 'Việc hôm nay ✅';
  static const String tourTasksBody =
      'Các thói quen cần làm hôm nay nằm ở đây. Làm xong thì chạm vào vòng tròn để đánh dấu.';
  static const String tourShortcutsTitle = 'Lối tắt nhanh 🧭';
  static const String tourShortcutsBody =
      'Góc của Gret, bản đồ biển… Ngọc trai kiếm được khi học dùng để sắm đồ và trang trí nhà Gret.';
  static const String tourStartTitle = 'Giữ để bắt đầu học 💪';
  static const String tourStartBody =
      'Giữ nút này một chút như nổ máy xe. Gret cho bạn xem vài reel tiếp lửa ngắn rồi vào phiên '
      'học. Lỡ mở TikTok giữa chừng, Gret sẽ nhắc bạn quay lại.';
  static const String tourHabitsTitle = 'Thói quen và giờ nhắc ⏰';
  static const String tourHabitsBody =
      'Đặt mục tiêu, thêm thói quen và hẹn giờ học. Tới giờ Gret sẽ nhắc bạn.';
  static const String tourProgressTitle = 'Tiến độ 📈';
  static const String tourProgressBody =
      'Xem chuỗi ngày, báo cáo theo tuần, tháng và thống kê các phiên học của bạn.';
  static const String tourSettingsTitle = 'Cài đặt ⚙️';
  static const String tourSettingsBody =
      'Đổi tên gọi, làm lại quiz, chọn app cần nhắc và xem lại hướng dẫn này bất cứ lúc nào.';

  // ---------- 6.3 Tài khoản và đồng bộ (spec 016) ----------
  static const String accountTitle = 'Tài khoản';
  static const String accountGuestSubtitle = 'Chưa đăng nhập — dữ liệu chỉ lưu trên máy này';
  static const String accountHaveAccount = 'Đã có tài khoản? Đăng nhập';
  static const String accountSignIn = 'Đăng nhập';
  static const String accountSignUp = 'Tạo tài khoản';
  static const String accountNoAccountYet = 'Chưa có tài khoản? Tạo tài khoản';
  static const String accountEmail = 'Email';
  static const String accountPassword = 'Mật khẩu';
  static const String accountShowPassword = 'Hiện mật khẩu';
  static const String accountHidePassword = 'Ẩn mật khẩu';
  static const String accountForgotPassword = 'Quên mật khẩu?';
  static const String accountSendReset = 'Gửi link đặt lại';
  static const String accountResetSent =
      'Nếu email này có tài khoản, DisGret đã gửi link đặt lại mật khẩu';
  static const String accountCreated = 'Đã tạo tài khoản';
  static const String accountSignedIn = 'Đã đăng nhập';
  static const String accountSyncNow = 'Đồng bộ ngay';
  static const String accountSignOut = 'Đăng xuất';
  static const String accountSignOutDuringSession = 'Kết thúc phiên học trước khi đăng xuất';
  static const String accountDelete = 'Xoá tài khoản';
  static const String accountDeleteNeedsNetwork = 'Cần có mạng để xoá tài khoản';
  static const String accountGuestIntro =
      'Đăng nhập để giữ thói quen và lịch sử học khi đổi điện thoại. Không đăng nhập vẫn dùng '
      'được mọi tính năng.';
  static String accountSyncedAt(String time) => 'Đã đồng bộ lúc $time';
  static const String accountSyncing = 'Đang đồng bộ…';
  static const String accountNotSynced = 'Chưa đồng bộ — sẽ tự đồng bộ khi có mạng';
  static const String accountSignInAgain = 'Hãy đăng nhập lại';
  static const String accountGone = 'Tài khoản đã bị xoá. Dữ liệu vẫn còn trên máy này.';

  // Sign-in errors (research.md R10).
  static const String accountEmailInUse = 'Email này đã có tài khoản. Đăng nhập?';
  static const String accountWrongCredentials = 'Email hoặc mật khẩu không đúng';
  static const String accountInvalidEmail = 'Email không hợp lệ';
  static const String accountWeakPassword = 'Mật khẩu cần ít nhất 8 ký tự';
  static const String accountTooManyRequests =
      'Bạn thử quá nhiều lần. Hãy đợi vài phút rồi thử lại.';
  static const String accountNoNetwork = 'Không có mạng. Thử lại sau.';
  static const String accountGenericError = 'Đã có lỗi. Thử lại sau.';

  // Privacy notice before sign-up (spec FR-005, contracts/account-ui.md).
  static const String privacyTitle = 'Trước khi tạo tài khoản';
  static const String privacyLeavesTitle = 'Những gì được lưu lên tài khoản';
  static const String privacyLeaves =
      'Email; mục tiêu, thói quen, lịch sử ghi nhận và phiên học; kết quả quiz động lực và độ '
      'dài reel ưa thích; đã xem màn giới thiệu và cấp thành tích đã chúc mừng; lựa chọn trong '
      'Góc của Gret; nơi học.';
  static const String privacyWhereTitle = 'Lưu ở đâu';
  static const String privacyWhere = 'Máy chủ Google Firebase ở Singapore.';
  static const String privacyStaysTitle = 'Những gì chỉ ở trên máy này';
  static const String privacyStays =
      'Tên gọi, danh sách app cần nhắc, lịch sử xem reel và Reset break, quyền của điện thoại.';
  static const String privacyNoTracking =
      'DisGret không có quảng cáo, không theo dõi bạn và không chia sẻ dữ liệu cho ai.';
  static const String privacyDelete =
      '"Xoá tài khoản" trong Cài đặt xoá vĩnh viễn mọi dữ liệu lưu online.';
  static const String privacyUnder16 =
      'Nếu bạn dưới 16 tuổi, hãy hỏi ý kiến bố mẹ trước khi tạo tài khoản.';
  static const String privacyAgree = 'Tôi đã đọc và đồng ý';
  static const String privacyLater = 'Để sau';

  // Dialogs.
  static const String mergeTitle = 'Máy này đang có dữ liệu';
  static const String mergeMessage =
      'Tài khoản này đã có dữ liệu. Bạn muốn làm gì với dữ liệu đang có trên máy?';
  static const String mergeKeepBoth = 'Gộp dữ liệu trên máy vào tài khoản';
  static const String mergeUseAccount =
      'Chỉ dùng dữ liệu của tài khoản (xoá dữ liệu khách trên máy)';
  static const String signOutPendingTitle = 'Chưa lưu hết lên tài khoản';
  static String signOutPendingMessage(int n) =>
      'Có $n thay đổi chưa lưu lên tài khoản. Nếu đăng xuất bây giờ, các thay đổi này sẽ mất.';
  static const String signOutStay = 'Ở lại';
  static const String signOutAnyway = 'Vẫn đăng xuất';
  static const String deleteTitle = 'Xoá tài khoản?';
  static const String deleteMessage = 'Tài khoản và mọi dữ liệu lưu online sẽ bị xoá vĩnh viễn.';
  static const String deleteLocalToo = 'Xoá cả dữ liệu trên máy này';
  static const String deleteRetry = 'Thử lại';
  static const String accountDeleted = 'Đã xoá tài khoản';

  // ---------- 2.2 Nhắc giờ học (spec 009) ----------
  static const String reminderTitle = 'Gret đang đợi bạn 🐟';
  static String reminderBody(String habit, int minutes) =>
      'Tới giờ $habit rồi, chỉ $minutes phút thôi. Mình bắt đầu nhé?';
  static const String reminderChannel = 'Nhắc giờ học';
  static const String reminderChannelDescription =
      'Gret nhắc bạn vào giờ học đã đặt cho thói quen.';

  // ---------- Plan sheet ----------
  static const String planSheetTitle = 'Phiên học tiếp theo';
  static const String planHabit = 'Thói quen';
  static const String planDuration = 'Thời lượng';
  static const String planApply = 'Dùng kế hoạch này';

  // ---------- 5.6 Quán San Hô ----------
  static const String planPlace = 'Học ở';
  static const String placeSea = 'Biển của Gret';
  static const String placeCafe = 'Quán San Hô';
  static const String nextPlaceCafe = 'ở Quán San Hô';
  static String cafeSemantics(List<String> names) =>
      'Quán San Hô: Gret đang học cùng ${names.join(', ')}';
  static const String cafeOwnerName = 'Rùa';
  static const String cafeOwnerRole = 'Chủ quán';
  static const String cafeStarfishName = 'Sao';
  static const String subjectMaths = 'Toán';
  static const String subjectLiterature = 'Văn';
  static const String subjectEnglish = 'Tiếng Anh';
  static const String subjectBiology = 'Sinh học';
  static const List<String> cafeStarted = [
    'Chào mừng đến Quán San Hô! Bàn của bạn đây.',
    'Vào đi, cả quán đang học nè.',
  ];
  static const List<String> cafeReturned = [
    'Mừng bạn quay lại! Mình vẫn ở đây.',
    'Quay lại rồi à? Học tiếp cùng nhau nhé.',
    'Không sao, mình cũng hay lạc đề mà.',
  ];
  static const List<String> cafeBreakStarted = [
    'Nghỉ chút thôi, uống ngụm trà nào.',
    'Vươn vai cái đã!',
  ];
  static const List<String> cafeBreakEnded = ['Học tiếp thôi!', 'Hiệp mới, cố lên nào.'];
  static const List<String> cafeHalfway = ['Được nửa đường rồi đó!', 'Bạn đang làm tốt lắm.'];

  /// Ready-made greetings (FR-007) and, at the same index, the replies they can get.
  static const List<String> cafeGreetings = [
    'Chào cả quán!',
    'Cố lên nhé!',
    'Mình nghỉ chút',
    'Cảm ơn nha!',
  ];
  static const List<List<String>> cafeReplies = [
    ['Chào bạn! Ngồi đây nè.', 'Chào bạn, học vui nha!'],
    ['Cùng cố lên!', 'Cố lên, mình cũng đang cố nè.'],
    ['Nghỉ xíu rồi học tiếp nha.', 'Ừ, nghỉ cho khỏe.'],
    ['Không có gì đâu!', 'Có bạn học cùng vui hơn hẳn.'],
  ];

  // ---------- Motivation step ----------
  static String startMinutes(int n) => 'Bắt đầu $n phút';
  static const String smallStep = 'Chỉ 5 phút thôi';
  static const String skip = 'Bỏ qua';
  static const String backToStudy = 'Quay lại học';
  static const String nextReel = 'Tiếp';

  /// Position of the current reel in the playlist, e.g. "1/3".
  static String reelPosition(int current, int total) => '$current/$total';
  static String reelPositionLabel(int current, int total) => 'Reel $current trên $total';
  static const String endCardStartTitle = 'Giờ đến lượt bạn';
  static const String endCardBackTitle = 'Quay lại phiên học nhé';
  static const String reelsLoadError = 'Không tải được danh sách reel.';
  static const String reelPlayError = 'Không phát được video này.';
  static const String noMatchingReel = 'Chưa có reel phù hợp.';

  // ---------- Running session ----------
  static const String focusTitle = 'Phiên học';
  static const String sessionOnBreak = 'Đang nghỉ';
  static String sessionRemaining(String clock) => 'Còn $clock';
  static const String openSession = 'Mở phiên học đang chạy';
  static const String focusRemaining = 'Thời gian còn lại';
  static String focusBreakRemaining(String clock) => 'Đang nghỉ – còn $clock';
  static const String focusedLabel = 'Tập trung thực';
  static const String distractionsLabel = 'Số lần xao nhãng';
  static const String finishEarly = 'Kết thúc sớm';
  static const String finishEarlyTitle = 'Kết thúc sớm?';
  static const String finishEarlyMessage = 'Phiên học vẫn được lưu với thời gian bạn đã tập trung.';
  static const String finishEarlyConfirm = 'Kết thúc';

  // ---------- 3.4 Tổng kết (restyled by feature 003) ----------
  static const String summaryTitle = 'Tổng kết';
  static const String summaryWellDone = 'Làm tốt lắm!';
  static const String summaryRecorded = 'Đã ghi nhận phiên học';
  static const String summaryStreakGained = '+1 ngày streak 🔥';
  static const String summaryHabitDone = 'Đã hoàn thành thói quen hôm nay';
  static const String summaryFocused = 'Thời gian tập trung';
  static const String summaryPlanned = 'Thời lượng đã đặt';
  static String summaryMinutes(int minutes) => '$minutes phút';
  static const String summaryAway = 'Thời gian ở ngoài';
  static const String summaryBlocked = 'Reset break đã chặn';
  static const String summaryBreaks = 'Nghỉ có chủ đích';
  static String summaryTimes(int times) => '$times lần';
  static const String summaryRatingPrompt = 'Bạn đánh giá phiên này thế nào?';
  static String summaryStars(int stars) => '$stars sao';
  static const String summaryNote = 'Ghi chú ngắn (không bắt buộc)';
  static String pearlGain(int pearls) => '+$pearls ngọc trai';

  // ---------- Tiến độ ----------
  static const String progressHabits = 'Thói quen';
  static const String progressSessions = 'Phiên học';
  static const String progressEmpty = 'Tiến độ sẽ hiện ở đây sau phiên học đầu tiên.';
  static const String reelsFollowedByStart = 'Bắt đầu học ngay sau khi xem';

  // ---------- Thói quen ----------
  static const String habitsByDay = 'Theo ngày';

  // ---------- 5.3 Gret và biển sống (feature 003) ----------
  static const String seaTitle = 'Biển của Gret';
  static const String greetingMorning = 'Chào buổi sáng';
  static const String greetingAfternoon = 'Chào buổi chiều';
  static const String greetingEvening = 'Chào buổi tối';

  /// Greeting by time of day: before 11:00 morning, before 18:00 afternoon, then evening.
  /// 5.1 The header greeting, followed by the student's name when there is one (spec 007).
  static String greetingFor(DateTime now, String name) =>
      name.isEmpty ? greeting(now) : '${greeting(now)}, $name';

  static String greeting(DateTime now) => now.hour < 11
      ? greetingMorning
      : now.hour < 18
      ? greetingAfternoon
      : greetingEvening;

  static const String clarityClear = 'Biển trong';
  static const String clarityHazy = 'Hơi đục';
  static const String clarityMurky = 'Đục';
  static const String streakLabel = 'chuỗi ngày';
  static String streakDays(int days) => '$days ngày';

  /// Screen-reader label of the streak (same wording as the former streak ring).
  static String streakSemantics(int days) => 'Chuỗi $days ngày học liên tiếp';
  static String clarityPercent(int percent) => '$percent%';
  static String clarityGain(int points) => '+$points% độ trong';
  static const String seaReady = 'Biển của bạn đã sẵn sàng';

  static const String headlineTop = 'Bớt lướt.';
  static const String headlineBottom = 'Học nhiều hơn.';
  static const String gretGoalPrompt = 'Đặt mục tiêu đầu tiên nhé!';

  // ---------- Onboarding (5.1, restyled by feature 003) ----------
  static const String storySkip = 'Bỏ qua';
  static const String storyHello = 'Chào bạn! Mình là Gret. Biển này là biển của bạn đó.';
  static const String storyScroll =
      'Mỗi lần bạn lướt reel quá lâu, biển của mình lại đục đi một chút…';
  static const String storyStudy = 'Còn mỗi phút bạn học, biển lại trong xanh, cá bơi về đông vui.';
  static const String storyCallBack =
      'Lỡ bị app khác kéo đi giữa giờ học? Mình sẽ gọi bạn quay lại.';

  /// Screen-reader label of the story progress segments.
  static String storyProgress(int page, int total) => 'Trang $page/$total';
  static const String appsQuestion = 'App nào hay kéo bạn đi nhất?';
  static const String appsHint =
      'Mở mấy app này lúc đang học, Gret sẽ gọi bạn quay lại. Đổi lại được trong Cài đặt.';
  static const String reelLengthQuestion = 'Bạn thích reel dài bao nhiêu?';
  static String reelSeconds(int seconds) => '$seconds giây';
  static const String continueLabel = 'Tiếp tục';
  static const String firstGoalTitle = 'Mục tiêu đầu tiên của bạn';
  static const String firstGoalMessage =
      'Đặt một mục tiêu và một thói quen nhỏ để bắt đầu ngay hôm nay.';
  static const String enterApp = 'Vào DisGret';
  static String quizStep(int number, int total) => 'Câu $number/$total';

  // ---------- Quiz (spec 015) ----------
  static const String quizNext = 'Tiếp';
  static String quizChooseUpTo(int max, int count) =>
      max >= count ? 'Chọn tất cả những gì đúng với bạn' : 'Chọn tối đa $max';
  static const String quizRetake = 'Làm lại quiz động lực';
  static const String quizRetakeTitle = 'Quiz động lực';
  static const String quizExtra = 'Giúp app hiểu bạn hơn';
  static const String quizExtraSubtitle = '4 câu, khoảng 40 giây, để reel hợp với bạn hơn';
  static const String profileReasons = 'Động lực chính';
  static const String profileFormats = 'Dạng video bạn thích';
  static const String profileTone = 'Kiểu cú hích';
  static String quizSaved(String reasons) => 'Động lực chính của bạn: $reasons';
  static const String quizExtraSaved = 'Đã cập nhật hồ sơ, reel sẽ hợp với bạn hơn';

  // ---------- 5.4 Góc của Gret (feature 004) ----------
  static const String cornerTitle = 'Góc của Gret';
  static const String cornerOpen = 'Mở Góc của Gret';
  static String cornerPearls(int pearls) => '$pearls ngọc trai';
  static const String cornerPearlsHint = 'Mỗi 5 phút tập trung được 1 ngọc trai.';
  static const String cornerTabWardrobe = 'Tủ đồ';
  static const String cornerTabSea = 'Biển';
  static const String cornerTabMascots = 'Linh vật';
  static const String cornerFilterAll = 'Tất cả';
  static const String cornerFilterOwned = 'Đã có';
  static const String cornerFilterPearls = 'Ngọc trai';
  static const String cornerFilterStreak = 'Chuỗi ngày';
  static const String cornerFilterShop = 'Cửa hàng';
  static const String rarityCommon = 'Thường';
  static const String rarityRare = 'Hiếm';
  static const String raritySpecial = 'Đặc biệt';
  static const String cornerWearing = 'Đang mặc';
  static const String cornerChosen = 'Đang chọn';
  static const String cornerOwned = 'Đã có';
  static const String cornerFree = 'Có sẵn';
  static const String cornerSoon = 'Sắp có';
  static String cornerPrice(int pearls) => '$pearls ngọc';
  static String cornerStreak(int days) => 'Chuỗi $days ngày';
  static String cornerOwnedCount(int owned, int total) => '$owned/$total món';
  static const String cornerNothingWorn = 'Gret chưa mặc gì';
  static String cornerWornList(String names) => 'Đang mặc: $names';
  static const String cornerGretOnly = 'Đồ trong tủ chỉ dành cho Gret. Chọn Gret để mặc thử.';
  static String cornerObtain(int pearls) => 'Đổi $pearls ngọc trai';
  static const String cornerWear = 'Mặc';
  static const String cornerTakeOff = 'Cởi ra';
  static const String cornerChoose = 'Chọn';
  static String cornerMissing(int pearls) => 'Còn thiếu $pearls ngọc trai. Học thêm nhé!';
  static String cornerNeedStreak(int days) => 'Mở khi bạn đạt chuỗi $days ngày học.';
  static const String cornerPremium = 'Món này sẽ bán bằng tiền thật. Sắp có!';
  static String cornerGot(String name) => '$name đã là của bạn!';
  static String cornerSeaLocked(int days) => 'Mở ở chuỗi $days ngày';

  /// Friends earned by studying (spec 020): progress on the card, the goal in the sheet.
  static String cornerOnTimeProgress(int done, int goal) => '$done/$goal lần đúng giờ';
  static String cornerReturnsProgress(int done, int goal) => '$done/$goal lần quay lại';

  /// Shorter forms for the narrow cards ("rarity · status" on one line).
  static String cornerOnTimeShort(int done, int goal) => '$done/$goal đúng giờ';
  static String cornerReturnsShort(int done, int goal) => '$done/$goal quay lại';
  static String cornerHoursProgress(double hours, int goal) => '${_tenths(hours)}/$goal giờ';
  static String cornerDaysProgress(int done, int goal) => '$done/$goal ngày';
  static String cornerNeedOnTime(int times) =>
      'Bắt đầu học trong 10 phút sau lời nhắc của thói quen, $times lần.';
  static String cornerNeedReturns(int times) => 'Chọn "Quay lại học" ở màn can thiệp $times lần.';
  static String cornerNeedHours(int hours) => 'Học tập trung tổng cộng $hours giờ.';
  static String cornerNeedDays(int days) => 'Một thói quen đạt $days ngày đã làm.';
  static String cornerSoFar(String progress) => 'Đã được: $progress';

  /// The drawing style of every mascot (spec 020).
  static const String cornerStyleTitle = 'Nét vẽ';
  static const String styleClassic = 'Cổ điển';
  static const String styleFlat = 'Phẳng viền';
  static const String styleSoft = '3D mềm';

  /// Gret's home in the sea (spec 021).
  static const String cornerDecorTitle = 'Trang trí nhà Gret';
  static const String cornerDecorHint =
      'Đồ trang trí đứng cạnh nhà vỏ ốc của Gret trên biển Hôm nay. Mỗi chỗ đặt được một món.';
  static const String cornerPlace = 'Đặt';
  static const String cornerPutAway = 'Cất đi';
  static const String cornerPlaced = 'Đang đặt';
  static const String cornerDecorDetail = 'Trang trí';

  /// How Quán San Hô is drawn (spec 021).
  static const String cornerCafeTitle = 'Kiểu quán';
  static const String cafeCosy = 'Ấm cúng';
  static const String cafeDiorama = 'Phòng mô hình';

  /// One decimal with a comma, rounded down and without ",0" ("6,5", "10").
  static String _tenths(double value) {
    final tenths = (value * 10).floor();
    return tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10},${tenths % 10}';
  }

  static const String cornerPreviousSea = 'Biển trước';
  static const String cornerNextSea = 'Biển sau';

  // ---------- 5.5 Bản đồ biển (feature 005) ----------
  static const String mapView = 'Bản đồ';
  static const String mapTitle = 'Bản đồ biển';
  static String mapExploration(String sea, int percent) => '$sea · Độ khám phá $percent%';
  static const String mapUnknown = 'Vùng chưa biết';

  /// A pearl sea Gret owns, as its own island (spec 014).
  static const String mapGretSea = 'Biển của Gret';
  static const String mapChooseSea = 'Chọn làm biển của Gret';
  static const String mapSeaInUse = 'Đang dùng';
  static String mapSeaSemantics(String sea) => '$sea, biển của Gret';
  static const String mapZoomIn = 'Phóng to';
  static const String mapZoomOut = 'Thu nhỏ';
  static const String mapToGret = 'Về chỗ Gret';
  static String mapExplored(int percent) => 'Đã khám phá $percent%';
  static const String mapHint = 'Sương mù tan dần mỗi ngày bạn làm thói quen.';
  static String mapRegionLine(String sea, int percent) => '$sea · $percent%';
  static String mapDays(int days, int total) => '$days/$total';
  static String mapDaysLong(int days, int total) => '$days/$total ngày';
  static const String mapStageHidden = 'Chưa khám phá';
  static const String mapStageFound = 'Đã tìm thấy';
  static const String mapStageWarmUp = 'Khởi động';
  static const String mapStageSteady = 'Bền bỉ';
  static const String mapStageSolid = 'Vững vàng';
  static const String mapStageFormed = 'Thành thói quen';
  static const String mapFishCave = 'Hang cá';
  static const String mapShipwreck = 'Tàu đắm';
  static const String mapKelpGarden = 'Vườn tảo';
  static const String mapTreasure = 'Kho báu';
  static const String mapCoralTemple = 'Đền san hô';
  static const String mapOldAnchor = 'Mỏ neo cổ';
  static String mapDiscoverHint(String habit) => 'Làm "$habit" lần đầu để khám phá điểm này.';
  static const String mapEmptyRegion = 'Vùng này chưa có điểm nào. Thêm một thói quen để khám phá.';
  static const String mapGretHere = 'Gret đang ở đây';
  static String mapRegionSemantics(String goal, String sea, int percent) =>
      'Vùng $goal, $sea, đã khám phá $percent%';
  static String mapPointSemantics(String habit, String kind, String progress) =>
      '$habit: $kind, $progress';
  static String mapHiddenSemantics(String habit) => '$habit: chưa khám phá';

  static const String moodHappy = 'đang vui';
  static const String moodNeutral = 'đang bình thường';
  static const String moodSad = 'đang buồn';
  static const String moodFocused = 'đang tập trung';
  static const String moodSleeping = 'đang ngủ';
  static const String moodCelebrating = 'đang ăn mừng';
  static const String moodLove = 'đang thương bạn';
  static const String moodSurprised = 'đang ngạc nhiên';
  static const String moodProud = 'đang tự hào';
  static const String moodWink = 'đang nháy mắt';

  /// Screen-reader description of a sea scene (spec FR-018).
  static String seaSemantics(String mood, int percent) => 'Gret $mood. Biển trong $percent%.';

  /// What Gret says when tapped, by mood. Encouraging, never blaming (spec FR-008).
  static const List<String> gretHappy = [
    'Biển trong veo luôn! Hôm nay mình bơi được xa ghê.',
    'Bạn học đều quá, mình thấy rõ cả san hô dưới đáy!',
    'Cảm ơn bạn đã giữ biển sạch nha.',
    'Hôm nay mình vui lắm. Học thêm chút nữa không?',
    'Nước trong thế này, mình muốn nhảy lên khỏi mặt biển luôn!',
  ];
  static const List<String> gretNeutral = [
    'Biển hơi lăn tăn. Một phiên ngắn là trong lại ngay.',
    'Mình ổn! Học 5 phút với mình không?',
    'Hôm nay mình đợi bạn đó.',
    'Mỗi phút học là một chút nước trong hơn.',
    'Bắt đầu nhỏ thôi cũng được mà.',
  ];
  static const List<String> gretSad = [
    'Biển hơi đục rồi… Học 5 phút với mình nhé?',
    'Không sao đâu, mình bắt đầu lại từ hôm nay.',
    'Mình nhớ bạn. Quay lại học chút nha?',
    'Chỉ cần một phiên là biển đỡ đục nhiều rồi.',
    'Từng chút một thôi, mình đi cùng bạn.',
  ];
  static const List<String> gretFocused = [
    'Mình đang tập trung cùng bạn đây!',
    'Biển đang trong dần lên kìa.',
    'Cố lên, sắp xong rồi!',
  ];
  static const List<String> gretSleeping = [
    'Zzz… Nghỉ ngơi cũng là một phần của học.',
    'Hết giờ nghỉ mình gọi bạn nha.',
  ];
  static const List<String> gretCelebrating = [
    'Tuyệt vời! Biển trong hơn hẳn rồi!',
    'Bạn làm được rồi, mình tự hào lắm!',
  ];
  static const List<String> gretLove = [
    'Mình thương bạn nhất luôn!',
    'Có bạn học cùng, mình vui ghê.',
  ];
  static const List<String> gretSurprised = [
    'Ồ! Bạn giữ thói quen lâu thế rồi sao?',
    'Một cột mốc mới kìa!',
  ];
  static const List<String> gretProud = [
    'Bạn quay lại học rồi, mình tự hào lắm!',
    'Trọn một phiên luôn, giỏi quá!',
  ];
  static const List<String> gretWink = [
    'Bí mật nhỏ: học 5 phút là biển trong hơn đó.',
    'Hôm nay mình cùng cố nha!',
  ];
}
