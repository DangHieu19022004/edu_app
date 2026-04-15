class AppTexts {
    // ------------------------------
    // Common
    // ------------------------------
    static const String appName = 'EduTeacher';
    static const String ErrorAuth = 'Mất kết nối, vui lòng kiểm tra lại mạng.';

    // ------------------------------
    // Login Screen
    // ------------------------------
    static const String loginTitle = 'Đăng nhập';
    static const String loginWelcome = 'Chào mừng bạn trở lại với EduTeacher';
    static const String emailLabel = 'Email';
    static const String passwordLabel = 'Mật khẩu';
    static const String emailHint = 'email@email.com';
    static const String passwordHint = '••••••••';
    static const String rememberMe = 'Ghi nhớ đăng nhập';
    static const String forgotPassword = 'Quên mật khẩu?';
    static const String loginButton = 'Đăng nhập';
    static const String noAccount = 'Chưa có tài khoản?  ';
    static const String signUpNow = 'Đăng ký ngay';
    static const String loginError = 'Đăng nhập thất bại. Vui lòng kiểm tra thông tin và thử lại.';
    static const String loginFBFailed = 'Đăng nhập bằng Facebook thất bại. Vui lòng thử lại.';
    static const String loginGoogleFailed = 'Đăng nhập bằng Google thất bại. Vui lòng thử lại.';

    // ------------------------------
    // Signin Screen
    // ------------------------------
    static const String signInTitle = 'Tham gia EduTeacher';
    static const String signInWelcome =
        'Chào mừng bạn đến với cộng đồng giáo dục hiện đại';
    static const String fullNameLabel = 'Họ và tên';
    static const String fullNameHint = 'Nhập họ và tên của bạn';
    static const String workEmailLabel = 'Email công việc';
    static const String workEmailHint = 'email@truonghoc.edu.vn';
    static const String signInPasswordHint = 'Tối thiểu 8 ký tự';
    static const String schoolLabel = 'Tên trường';
    static const String schoolHint = 'Trường THPT hoặc Đại học';
    static const String createAccount = 'Tạo tài khoản';
    static const String haveAccount = 'Đã có tài khoản?  ';

    // ------------------------------
    // Shared Actions / Divider
    // ------------------------------
    static const String orUpper = 'HOẶC';
    static const String orLower = 'Hoặc';
    static const String continueWithGoogle = 'Tiếp tục với Google';
      static const String continueWithFacebook = 'Tiếp tục với Facebook';

    // ------------------------------
    // Footer Links
    // ------------------------------
    static const String terms = 'Điều khoản';
    static const String privacy = 'Chính sách bảo mật';
    static const String support = 'Trợ giúp';

    // ------------------------------
    // Dashboard Screen
    // ------------------------------
    static const String dashboardGreeting = 'Xin chào';
    static const String dashboardSubGreeting = 'Hôm nay bạn muốn làm gì?';
    static const String dashboardSearchHint = 'Tìm kiếm học bạ, học sinh...';
    static const String dashboardMainFeatures = 'Tính năng chính';
    static const String dashboardRecentActivity = 'Hoạt động gần đây';
    static const String viewAll = 'Xem tất cả';

    // ------------------------------
    // preOCR Screen
    // ------------------------------
    static const String preOcrTitle = 'Quét học bạ';
    static const String preOcrChooseFromDevice = 'Chọn ảnh từ thiết bị';
    static const String preOcrCaptureByCamera = 'Chụp ảnh bằng camera';
    static const String preOcrSelectedImages = 'Ảnh đã chọn';
    static const String preOcrEmptyHint =
      'Chưa có ảnh nào. Hãy chọn ảnh hoặc chụp ảnh để tiếp tục.';
    static const String preOcrConfirm = 'Xác nhận';
    static const String preOcrGuideTitle = 'Hướng dẫn chụp và chọn ảnh';
    static const String preOcrGuideBody =
      '1. Chụp đủ sáng, không bóng mờ, không nghiêng ảnh.\n'
      '2. Chụp trọn trang học bạ và không cắt mất thông tin.\n'
      '3. Chọn đúng nhãn ảnh trước khi bấm Xác nhận.';
    static const String preOcrTapToPreview = 'Nhấn vào ảnh để xem toàn bộ';
    static const String preOcrImageLabel = 'Chọn nhãn ảnh';
    static const String preOcrExitPreview = 'Thoát xem ảnh';
    static const String preOcrPreviewHint = 'Phóng to/thu nhỏ để kiểm tra độ rõ';

    // ------------------------------
    // OCR Screen
    // ------------------------------
    static const String ocrPreviewTitle = 'Bản xem trước học bạ';
    static const String ocrPreviewHint =
        'Vui lòng đảm bảo hình ảnh rõ nét để nhận diện chính xác nhất';
    static const String ocrProgressLabel = 'Đang trích xuất dữ liệu học bạ...';
    static const String ocrResultTitle = 'Kết quả trích xuất';
    static const String ocrStudentName = 'Họ và tên học sinh';
    static const String ocrGender = 'Giới tính';
    static const String ocrDateOfBirth = 'Ngày sinh';
    static const String ocrClass = 'Lớp';
    static const String ocrSemester = 'Học kỳ';


    // ------------------------------
    // Detail HBA Screen
    // ------------------------------
    static const String detailHbaTitle = 'Chi tiết bảng điểm';
    static const String detailHbaSubtitle = 'Kết quả chi tiết';
    static const String detailResultTitle = 'Kết quả chi tiết';
    static const String detailTeacherComment = 'Nhận xét của giáo viên';
    static const String detailAnalyzeAi = 'Phân tích AI';
    static const String detailExportReport = 'Xuất báo cáo';

    // ------------------------------
    // Chatbot Screen
    // ------------------------------
    static const String chatbotTitle = 'Trợ lý giáo viên';
    static const String chatbotInputHint = 'Nhập câu hỏi của bạn...';
    static const String chatbotTimeout = 'Chatbot đang xử lý dữ liệu. Vui lòng thử lại sau ít giây.';
    static const String chatbotHint1 = 'Phân tích học lực';
    static const String chatbotHint2 = 'Đề xuất phương pháp giảng dạy';
    static const String chatbotHint3 = 'Học sinh của tôi nên thi ngành nào?';
    static const String chatbotError = 'Chatbot bận mất rồi. Vui lòng thử lại.';

    // ------------------------------
    // Classroom Management
    // ------------------------------
    static const String classroomDeleteSuccess = 'Xóa lớp thành công';
    static const String classroomCreateSuccess = 'Tạo lớp thành công';
    static const String classroomSaveFailed = 'Lưu lớp thất bại';
    static const String classroomDeleteFailed = 'Không thể xóa lớp. Vui lòng thử lại.';
    // ------------------------------
    // Email Screen
    // ------------------------------
    static const String emailIdUnknown = 'Email id không hợp lệ';

    // ------------------------------
    // Analysis Messages
    // ------------------------------
    static const String analysTitle = 'Phân tích học lực';
    static const String analysOverall = 'Tổng quan học lực';
    static const String analysErrorLoading = 'Không thể tải dữ liệu phân tích. Vui lòng thử lại sau.';
    static const String analysInvalidData = 'Dữ liệu không hợp lệ';
    static const String analysNoData = 'Bộ lọc hiện tại không có dữ liệu phù hợp.';
    static const String analysInvalidClass = 'Vui lòng chọn lớp để xem thống kê.';
    static const String improvePerformanceSuggestion = 'Cần cải thiện';
    static const String chooseClass = 'Chọn lớp';
    static const String chooseSemester = 'Học kỳ';
    static const String chooseGrade = 'Khối';
    static const String AllGrade = 'Tất cả Khối';
    static const String averageScoreClass = 'ĐTB lớp ';
    static const String percentGioiKha = 'Giỏi + Khá';
    static const String validStudentCount = 'HS hợp lệ';
    static const String excellent = 'Xuất sắc';
    static const String good = 'Khá';
    static const String CharTitle = 'Phân bố học lực';
    static const String trendTitle = 'Xu hướng GPA theo khối';
    static const String Grade10 = 'Khối 10';
    static const String Grade11 = 'Khối 11';
    static const String Grade12 = 'Khối 12';
    static const String weakSubjectSuggestion = 'Điểm yếu cần cải thiện';
    static const String noWeakSubjects = 'Không có môn yếu theo ngưỡng hiện tại.';

    // ------------------------------
    // Manage Academic Transcript Screen
    // ------------------------------
    static const String emptyStudentInClass = 'Lớp học này chưa có học sinh';
    static const String emptyStudentName = 'Học sinh';
    static const String putTranscriptDetail = 'Sửa học bạ';
    static const String deleteTranscript = 'Xóa học bạ';
    static const String gender = 'Giới tính';
    static const String dateOfBirth = 'Ngày sinh';
    static const String phone = 'Điện thoại';
    static const String school = 'Trường học';
    static const String invalidStudent = 'Không tìm thấy học sinh';
    static const String invalidStudentDetail = 'Bản ghi học sinh không có học sinh hợp lệ.';
    static const String deleteTranscriptSuccess = 'Xóa học bạ thành công';
    static const String CannotDeleteTranscriptAlert = 'Không thể xóa học bạ. Vui lòng thử lại.';
    static const String ConfirmDeleteTranscript = 'Xác nhận xóa học bạ';
    static const String classroomLoadFailed = 'Không thể tải danh sách lớp. Vui lòng thử lại.';
    static const String studentSaveFailed = 'Không thể tải danh sách học sinh. Vui lòng thử lại.';
    static const String schoolYearRequired = 'Vui lòng nhập năm học';
    static const String invalidSchoolYear = 'Năm học không đúng định dạng yyyy-yyyy';
    static const String newClassroom = 'Tạo lớp học mới';
    static const String closeForm = 'Đóng form';
    static const String confirm = 'Xác nhận';
    static const String ConfirmDeleteClassroom = 'Xác nhận xóa lớp';
    static const String detailNoTeacherComment = 'Chưa có nhận xét từ giáo viên.';
    static const String detailNoScoresForGrade = 'Không có dữ liệu điểm cho lớp này.';
    static const String StudentName = 'Họ tên';
    static const String classroom = 'Lớp';
    static const String detailStudentInfo = 'Thông tin chung sinh viên';
}
