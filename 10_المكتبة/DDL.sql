-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                            نظام المكتبة المدرسية                             ║
-- ║                    Library System Database Schema                             ║
-- ║                                                                               ║
-- ║           يشمل: الكتب، التصنيفات، الإعارات، الجرد، التقارير                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-10
-- الإصدار: 1.0
-- المهندس المسؤول: أحمد الهتار / موسى العواضي
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 1: جداول Lookup للمكتبة
-- ═══════════════════════════════════════════════════════════════════════════════

-- جدول حالات الكتاب
CREATE TABLE IF NOT EXISTS lookup_book_conditions (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    description VARCHAR(100) COMMENT 'وصف الحالة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات الكتاب الفيزيائية';

INSERT INTO lookup_book_conditions (name_ar, code, description) VALUES
('ممتاز', 'EXCELLENT', 'كتاب جديد أو شبه جديد'),
('جيد', 'GOOD', 'كتاب بحالة جيدة مع استخدام خفيف'),
('مقبول', 'ACCEPTABLE', 'كتاب بحالة مقبولة مع علامات استخدام'),
('تالف', 'DAMAGED', 'كتاب تالف يحتاج إصلاح أو استبدال');

-- جدول حالات الإعارة
CREATE TABLE IF NOT EXISTS lookup_loan_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الحالة بالعربية',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT 'رمز الحالة',
    color VARCHAR(10) COMMENT 'لون للعرض',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات الإعارة';

INSERT INTO lookup_loan_statuses (name_ar, code, color) VALUES
('معار', 'BORROWED', '#3498db'),
('مُرجع', 'RETURNED', '#2ecc71'),
('متأخر', 'OVERDUE', '#e74c3c'),
('مفقود', 'LOST', '#9b59b6'),
('تالف', 'DAMAGED', '#f39c12');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 2: تصنيفات الكتب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS book_categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- معلومات التصنيف
    name_ar VARCHAR(100) NOT NULL COMMENT 'اسم التصنيف بالعربية',
    name_en VARCHAR(100) COMMENT 'اسم التصنيف بالإنجليزية',
    code VARCHAR(20) UNIQUE COMMENT 'رمز التصنيف (تصنيف ديوي مثلاً)',
    
    -- التصنيف الهرمي
    parent_id INT UNSIGNED NULL COMMENT 'التصنيف الأم',
    level TINYINT UNSIGNED DEFAULT 1 COMMENT 'مستوى التصنيف',
    
    -- معلومات إضافية
    description TEXT COMMENT 'وصف التصنيف',
    icon VARCHAR(50) COMMENT 'أيقونة التصنيف',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    sort_order SMALLINT DEFAULT 0 COMMENT 'ترتيب العرض',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_bookcat_parent FOREIGN KEY (parent_id) 
        REFERENCES book_categories(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_bookcat_parent (parent_id),
    INDEX idx_bookcat_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='تصنيفات الكتب';

-- البيانات الأولية لتصنيفات الكتب
INSERT INTO book_categories (name_ar, code, level, sort_order) VALUES
('العلوم الإسلامية', 'ISL', 1, 1),
('اللغة العربية وآدابها', 'ARB', 1, 2),
('اللغات الأجنبية', 'LANG', 1, 3),
('العلوم الطبيعية', 'SCI', 1, 4),
('الرياضيات', 'MATH', 1, 5),
('التاريخ والجغرافيا', 'HIST_GEO', 1, 6),
('الأدب والقصص', 'LITERATURE', 1, 7),
('الموسوعات والمراجع', 'REFERENCE', 1, 8),
('الكتب المدرسية', 'TEXTBOOKS', 1, 9),
('كتب الأطفال', 'CHILDREN', 1, 10);

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 3: الكتب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS library_books (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- معلومات الكتاب الأساسية
    isbn VARCHAR(20) COMMENT 'الرقم الدولي ISBN',
    title VARCHAR(255) NOT NULL COMMENT 'عنوان الكتاب',
    subtitle VARCHAR(255) COMMENT 'عنوان فرعي',
    
    -- المؤلف والنشر
    author VARCHAR(200) COMMENT 'المؤلف',
    co_authors TEXT COMMENT 'مؤلفون مشاركون (JSON أو نص)',
    publisher VARCHAR(150) COMMENT 'دار النشر',
    publish_year YEAR COMMENT 'سنة النشر',
    edition VARCHAR(20) COMMENT 'الطبعة',
    
    -- التصنيف
    category_id INT UNSIGNED COMMENT 'التصنيف الرئيسي',
    
    -- الموقع في المكتبة
    shelf_location VARCHAR(50) COMMENT 'رقم الرف/الموقع',
    shelf_row TINYINT UNSIGNED COMMENT 'رقم الصف',
    
    -- النسخ
    total_copies SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'عدد النسخ الكلي',
    available_copies SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'النسخ المتاحة للإعارة',
    
    -- معلومات إضافية
    description TEXT COMMENT 'وصف الكتاب',
    language VARCHAR(30) DEFAULT 'العربية' COMMENT 'لغة الكتاب',
    pages SMALLINT UNSIGNED COMMENT 'عدد الصفحات',
    cover_type ENUM('غلاف عادي', 'غلاف مقوى', 'غير محدد') DEFAULT 'غير محدد',
    
    -- الحالة
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط',
    is_available_for_loan BOOLEAN DEFAULT TRUE COMMENT 'متاح للإعارة',
    
    -- السعر (اختياري)
    price DECIMAL(10,2) COMMENT 'سعر الكتاب',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft Delete',
    created_by_user_id INT UNSIGNED COMMENT 'أنشأه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) 
        REFERENCES book_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_book_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_book_isbn (isbn),
    INDEX idx_book_title (title),
    INDEX idx_book_author (author),
    INDEX idx_book_category (category_id),
    INDEX idx_book_available (is_available_for_loan, available_copies)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='كتب المكتبة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 4: نسخ الكتب (للتتبع الفردي)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS book_copies (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    book_id INT UNSIGNED NOT NULL COMMENT 'الكتاب',
    
    -- معلومات النسخة
    copy_number SMALLINT UNSIGNED NOT NULL COMMENT 'رقم النسخة',
    barcode VARCHAR(50) UNIQUE COMMENT 'الباركود',
    
    -- الحالة
    condition_id TINYINT UNSIGNED COMMENT 'حالة النسخة',
    is_available BOOLEAN DEFAULT TRUE COMMENT 'متاحة للإعارة',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات عن النسخة',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_copy_book FOREIGN KEY (book_id) 
        REFERENCES library_books(id) ON DELETE CASCADE,
    CONSTRAINT fk_copy_condition FOREIGN KEY (condition_id) 
        REFERENCES lookup_book_conditions(id) ON DELETE SET NULL,
    
    -- القيود
    UNIQUE KEY uk_copy_number (book_id, copy_number),
    INDEX idx_copy_barcode (barcode),
    INDEX idx_copy_available (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='نسخ الكتب الفردية';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 5: الإعارات
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS book_loans (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- الكتاب والنسخة
    book_id INT UNSIGNED NOT NULL COMMENT 'الكتاب',
    copy_id INT UNSIGNED COMMENT 'النسخة المحددة (اختياري)',
    
    -- المستعير
    borrower_type ENUM('طالب', 'موظف') NOT NULL COMMENT 'نوع المستعير',
    student_id INT UNSIGNED COMMENT 'معرف الطالب (إذا طالب)',
    employee_id INT UNSIGNED COMMENT 'معرف الموظف (إذا موظف)',
    
    -- تواريخ الإعارة
    loan_date DATE NOT NULL COMMENT 'تاريخ الإعارة',
    due_date DATE NOT NULL COMMENT 'تاريخ الإرجاع المتوقع',
    return_date DATE COMMENT 'تاريخ الإرجاع الفعلي',
    
    -- الحالة
    status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'حالة الإعارة',
    
    -- التجديد
    times_renewed TINYINT UNSIGNED DEFAULT 0 COMMENT 'عدد مرات التجديد',
    max_renewals TINYINT UNSIGNED DEFAULT 2 COMMENT 'الحد الأقصى للتجديد',
    
    -- الغرامات
    fine_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT 'مبلغ الغرامة (للتأخير)',
    fine_paid BOOLEAN DEFAULT FALSE COMMENT 'تم دفع الغرامة',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    created_by_user_id INT UNSIGNED COMMENT 'سجل الإعارة',
    returned_by_user_id INT UNSIGNED COMMENT 'سجل الإرجاع',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id) 
        REFERENCES library_books(id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_copy FOREIGN KEY (copy_id) 
        REFERENCES book_copies(id) ON DELETE SET NULL,
    CONSTRAINT fk_loan_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE SET NULL,
    CONSTRAINT fk_loan_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE SET NULL,
    CONSTRAINT fk_loan_status FOREIGN KEY (status_id) 
        REFERENCES lookup_loan_statuses(id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_creator FOREIGN KEY (created_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_loan_returner FOREIGN KEY (returned_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL,
    
    -- الفهارس
    INDEX idx_loan_book (book_id),
    INDEX idx_loan_borrower_student (borrower_type, student_id),
    INDEX idx_loan_borrower_employee (borrower_type, employee_id),
    INDEX idx_loan_dates (loan_date, due_date),
    INDEX idx_loan_status (status_id),
    INDEX idx_loan_overdue (due_date, status_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعارات الكتب';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 6: حجوزات الكتب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS book_reservations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    book_id INT UNSIGNED NOT NULL COMMENT 'الكتاب',
    
    -- المستعير
    borrower_type ENUM('طالب', 'موظف') NOT NULL COMMENT 'نوع المستعير',
    student_id INT UNSIGNED COMMENT 'معرف الطالب',
    employee_id INT UNSIGNED COMMENT 'معرف الموظف',
    
    -- تواريخ الحجز
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'تاريخ الحجز',
    expiry_date DATE NOT NULL COMMENT 'تاريخ انتهاء الحجز',
    
    -- الحالة
    status ENUM('نشط', 'ملغي', 'مكتمل', 'منتهي') DEFAULT 'نشط',
    
    -- ملاحظات
    notes TEXT COMMENT 'ملاحظات',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) 
        REFERENCES library_books(id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_student FOREIGN KEY (student_id) 
        REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    
    -- الفهارس
    INDEX idx_reservation_book (book_id),
    INDEX idx_reservation_status (status),
    INDEX idx_reservation_expiry (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حجوزات الكتب';

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 7: إعدادات المكتبة
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS library_settings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    setting_key VARCHAR(50) NOT NULL UNIQUE COMMENT 'مفتاح الإعداد',
    setting_value TEXT COMMENT 'قيمة الإعداد',
    description VARCHAR(200) COMMENT 'وصف الإعداد',
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by_user_id INT UNSIGNED COMMENT 'حدّثه',
    
    -- المفاتيح الخارجية
    CONSTRAINT fk_libsetting_updater FOREIGN KEY (updated_by_user_id) 
        REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='إعدادات المكتبة';

-- البيانات الأولية للإعدادات
INSERT INTO library_settings (setting_key, setting_value, description) VALUES
('default_loan_days', '14', 'مدة الإعارة الافتراضية بالأيام'),
('max_loans_student', '3', 'الحد الأقصى للإعارات للطالب'),
('max_loans_employee', '5', 'الحد الأقصى للإعارات للموظف'),
('max_renewals', '2', 'الحد الأقصى للتجديد'),
('fine_per_day', '0.5', 'الغرامة اليومية للتأخير'),
('reservation_expiry_days', '3', 'مدة صلاحية الحجز بالأيام');

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 8: Views للتقارير
-- ═══════════════════════════════════════════════════════════════════════════════

-- View قائمة الكتب مع التصنيفات
CREATE OR REPLACE VIEW v_library_books_full AS
SELECT 
    lb.id,
    lb.isbn,
    lb.title,
    lb.author,
    lb.publisher,
    lb.publish_year,
    bc.name_ar AS category_name,
    lb.shelf_location,
    lb.total_copies,
    lb.available_copies,
    lb.is_available_for_loan,
    CASE 
        WHEN lb.available_copies = 0 THEN 'غير متاح'
        WHEN lb.available_copies < lb.total_copies THEN 'متاح جزئياً'
        ELSE 'متاح'
    END AS availability_status
FROM library_books lb
LEFT JOIN book_categories bc ON lb.category_id = bc.id
WHERE lb.deleted_at IS NULL AND lb.is_active = TRUE;

-- View الإعارات الحالية
CREATE OR REPLACE VIEW v_current_loans AS
SELECT 
    bl.id AS loan_id,
    lb.title AS book_title,
    lb.author,
    CASE 
        WHEN bl.borrower_type = 'طالب' THEN s.full_name
        ELSE e.full_name
    END AS borrower_name,
    bl.borrower_type,
    bl.loan_date,
    bl.due_date,
    DATEDIFF(CURDATE(), bl.due_date) AS days_overdue,
    lls.name_ar AS status
FROM book_loans bl
JOIN library_books lb ON bl.book_id = lb.id
LEFT JOIN students s ON bl.student_id = s.id
LEFT JOIN employees e ON bl.employee_id = e.id
JOIN lookup_loan_statuses lls ON bl.status_id = lls.id
WHERE bl.return_date IS NULL;

-- View الكتب المتأخرة
CREATE OR REPLACE VIEW v_overdue_books AS
SELECT 
    bl.id AS loan_id,
    lb.title AS book_title,
    CASE 
        WHEN bl.borrower_type = 'طالب' THEN s.full_name
        ELSE e.full_name
    END AS borrower_name,
    bl.borrower_type,
    bl.due_date,
    DATEDIFF(CURDATE(), bl.due_date) AS days_overdue,
    (DATEDIFF(CURDATE(), bl.due_date) * 0.5) AS estimated_fine
FROM book_loans bl
JOIN library_books lb ON bl.book_id = lb.id
LEFT JOIN students s ON bl.student_id = s.id
LEFT JOIN employees e ON bl.employee_id = e.id
WHERE bl.return_date IS NULL 
  AND bl.due_date < CURDATE();

-- View إحصائيات المكتبة
CREATE OR REPLACE VIEW v_library_statistics AS
SELECT 
    (SELECT COUNT(*) FROM library_books WHERE deleted_at IS NULL AND is_active = TRUE) AS total_books,
    (SELECT SUM(total_copies) FROM library_books WHERE deleted_at IS NULL AND is_active = TRUE) AS total_copies,
    (SELECT SUM(available_copies) FROM library_books WHERE deleted_at IS NULL AND is_active = TRUE) AS available_copies,
    (SELECT COUNT(*) FROM book_loans WHERE return_date IS NULL) AS active_loans,
    (SELECT COUNT(*) FROM book_loans WHERE return_date IS NULL AND due_date < CURDATE()) AS overdue_loans,
    (SELECT COUNT(*) FROM book_reservations WHERE status = 'نشط') AS active_reservations;

-- View أكثر الكتب إعارة
CREATE OR REPLACE VIEW v_most_borrowed_books AS
SELECT 
    lb.id,
    lb.title,
    lb.author,
    bc.name_ar AS category_name,
    COUNT(bl.id) AS loan_count,
    MAX(bl.loan_date) AS last_loan_date
FROM library_books lb
LEFT JOIN book_loans bl ON lb.id = bl.book_id
LEFT JOIN book_categories bc ON lb.category_id = bc.id
WHERE lb.deleted_at IS NULL
GROUP BY lb.id, lb.title, lb.author, bc.name_ar
ORDER BY loan_count DESC;

-- ═══════════════════════════════════════════════════════════════════════════════
-- القسم 9: نظام العهد والأصول (Library Custody System - Hybrid Model)
-- ═══════════════════════════════════════════════════════════════════════════════
-- هذا القسم تم إضافته لتلبية متطلبات "العهد للمكتبة" مع دعم المرونة (Hybrid)
-- يدعم:
-- 1. أصول معرفة مسبقاً (Assets) أو أصول يدوية (Manual).
-- 2. مستلمين معرفين (Moy/Std) أو مستلمين يدويين (Other).

-- 9.1 تصنيفات الأصول
CREATE TABLE IF NOT EXISTS library_asset_categories (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL COMMENT 'أجهزة إلكترونية، أثاث، مفاتيح...',
    code VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تصنيفات أصول المكتبة';

INSERT INTO library_asset_categories (name_ar, code) VALUES 
('أجهزة إلكترونية', 'ELECTRONICS'),
('أثاث مكتبي', 'FURNITURE'),
('أدوات قرطاسية', 'STATIONERY'),
('مفاتيح وعهد صغيرة', 'KEYS_MISC');

-- 9.2 سجل الأصول الثابتة (للمواد المعرفة مسبقاً)
CREATE TABLE IF NOT EXISTS library_assets (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id TINYINT UNSIGNED NOT NULL,
    name_ar VARCHAR(200) NOT NULL,
    barcode VARCHAR(100) UNIQUE COMMENT 'باركود الأصل',
    serial_number VARCHAR(100) COMMENT 'الرقم التسلسلي للجهاز',
    
    -- الحالة والمكان
    status ENUM('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'DAMAGED', 'LOST') DEFAULT 'AVAILABLE',
    location VARCHAR(100) COMMENT 'مكان الحفظ الافتراضي',
    
    purchase_date DATE,
    price DECIMAL(10,2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES library_asset_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أصول المكتبة الثابتة';

-- 9.3 سجل العهد (الجدول الرئيسي - Hybrid)
CREATE TABLE IF NOT EXISTS library_custody_records (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- 1. ماذا تم تسليمه؟ (إما أصل معرف أو نص يدوي)
    asset_id INT UNSIGNED NULL COMMENT 'رابط للأصل المعرف',
    manual_asset_name VARCHAR(255) NULL COMMENT 'اسم العهدة يدوياً (للمرونة)',
    
    -- 2. لمن تم تسليمه؟ (إما موظف/طالب أو نص يدوي)
    recipient_type ENUM('EMPLOYEE', 'STUDENT', 'PARENT', 'OTHER') NOT NULL DEFAULT 'OTHER',
    employee_id INT UNSIGNED NULL,
    student_id INT UNSIGNED NULL,
    manual_recipient_name VARCHAR(200) NULL COMMENT 'اسم المستلم يدوياً (إذا كان ولي أمر أو أخرى)',
    
    -- 3. متى؟ (تحديد التاريخ بدقة حسب الصورة)
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL COMMENT 'الفصل الدراسي',
    hijri_month_id TINYINT UNSIGNED NULL COMMENT 'الشهر (من القائمة المنسدلة)',
    week_number TINYINT UNSIGNED NULL COMMENT 'الأسبوع',
    custody_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    
    -- 4. تفاصيل إضافية
    quantity SMALLINT UNSIGNED DEFAULT 1,
    is_returned BOOLEAN DEFAULT FALSE,
    return_date DATE NULL,
    
    notes TEXT COMMENT 'ملاحظات',
    created_by_user_id INT UNSIGNED COMMENT 'أمين المكتبة المسجل',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- القيود والمفاتيح
    FOREIGN KEY (asset_id) REFERENCES library_assets(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (hijri_month_id) REFERENCES lookup_hijri_months(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل عهد المكتبة المرن';

-- 9.4 View لتقرير العهد الشامل (يدمج البيانات المعرفة واليدوية)
CREATE OR REPLACE VIEW v_library_custody_report AS
SELECT 
    lcr.id,
    -- اسم العهدة (المعرف أو اليدوي)
    CASE 
        WHEN lcr.asset_id IS NOT NULL THEN la.name_ar 
        ELSE lcr.manual_asset_name 
    END AS asset_name,
    
    -- اسم المستلم (المعرف أو اليدوي)
    CASE 
        WHEN lcr.recipient_type = 'EMPLOYEE' THEN e.full_name 
        WHEN lcr.recipient_type = 'STUDENT' THEN s.full_name 
        ELSE lcr.manual_recipient_name 
    END AS recipient_name,
    
    lcr.recipient_type,
    lcr.custody_date,
    lcr.is_returned,
    lcr.return_date,
    ay.name_ar AS academic_year,
    sem.name_ar AS semester
    
FROM library_custody_records lcr
LEFT JOIN library_assets la ON lcr.asset_id = la.id
LEFT JOIN employees e ON lcr.employee_id = e.id
LEFT JOIN students s ON lcr.student_id = s.id
LEFT JOIN academic_years ay ON lcr.academic_year_id = ay.id
LEFT JOIN semesters sem ON lcr.semester_id = sem.id;

-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 10. (ملحق) Views التقويم التشغيلية (Library)
-- -----------------------------------------------------------------------------

-- View: تقويم إعارات المكتبة
CREATE OR REPLACE VIEW v_book_loans_calendar AS 
SELECT  
   bl.id, lb.title, 
   bl.loan_date, bl.due_date, 
   cm_due.hijri_date AS due_hijri, 
   cm_due.day_name_ar AS due_day_name, 
   cm_due.is_school_day AS due_is_school_day, 
   CASE 
       WHEN bl.borrower_type = 'طالب' THEN s.full_name 
       ELSE e.full_name 
   END AS borrower_name, 
   lls.name_ar AS status 
FROM book_loans bl 
LEFT JOIN calendar_master cm_due ON bl.due_date = cm_due.gregorian_date 
LEFT JOIN library_books lb ON bl.book_id = lb.id 
LEFT JOIN students s ON bl.student_id = s.id 
LEFT JOIN employees e ON bl.employee_id = e.id 
LEFT JOIN lookup_loan_statuses lls ON bl.status_id = lls.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- رسالة اكتمال التنفيذ
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT '✅ تم إنشاء جداول نظام المكتبة المدرسية بنجاح!' AS message;
SELECT CONCAT('📊 عدد الجداول: 12 جدول + 7 Views') AS summary;
