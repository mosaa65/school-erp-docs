-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     نظام إدارة المدرسة المتكامل                              ║
-- ║                School Management System Database                              ║
-- ║                                                                               ║
-- ║  الجزء 2: النواة الأكاديمية (Core Academic Structure)                        ║
-- ║  المسؤول: موسى العواضي (المهندس المسؤول)                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-05
-- الإصدار: 1.0
-- قاعدة البيانات: MySQL 8.0+

-- ═══════════════════════════════════════════════════════════════════════════════
-- النواة الأكاديمية - 8 جداول
-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 1. جدول المدرسة
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schools (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(150) NOT NULL COMMENT 'اسم المدرسة بالعربية',
    name_en VARCHAR(150) NULL COMMENT 'اسم المدرسة بالإنجليزية',
    school_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع المدرسة',
    ownership_type_id TINYINT UNSIGNED NOT NULL COMMENT 'نوع الملكية',
    period_id TINYINT UNSIGNED NOT NULL COMMENT 'فترة الدوام',
    
    -- بيانات التواصل
    phone VARCHAR(20) NULL,
    fax VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    website VARCHAR(255) NULL,
    
    -- الموقع
    governorate_id TINYINT UNSIGNED NULL,
    directorate_id SMALLINT UNSIGNED NULL,
    address TEXT NULL,
    
    -- بيانات إضافية
    establishment_year YEAR NULL COMMENT 'سنة التأسيس',
    license_number VARCHAR(50) NULL COMMENT 'رقم الترخيص',
    logo_path VARCHAR(255) NULL COMMENT 'مسار الشعار',
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    -- المفاتيح الخارجية
    FOREIGN KEY (school_type_id) REFERENCES lookup_school_types(id),
    FOREIGN KEY (ownership_type_id) REFERENCES lookup_ownership_types(id),
    FOREIGN KEY (period_id) REFERENCES lookup_periods(id),
    FOREIGN KEY (governorate_id) REFERENCES governorates(id),
    FOREIGN KEY (directorate_id) REFERENCES directorates(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='بيانات المدرسة الأساسية';

-- -----------------------------------------------------------------------------
-- 2. جدول الأعوام الدراسية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS academic_years (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'مثل: 1446-1447 هـ',
    name_en VARCHAR(50) NULL COMMENT 'مثل: 2024-2025',
    start_date_hijri VARCHAR(10) NULL COMMENT 'تاريخ البداية هجري',
    end_date_hijri VARCHAR(10) NULL COMMENT 'تاريخ النهاية هجري',
    start_date_gregorian DATE NULL COMMENT 'تاريخ البداية ميلادي',
    end_date_gregorian DATE NULL COMMENT 'تاريخ النهاية ميلادي',
    is_current BOOLEAN DEFAULT FALSE COMMENT 'العام الحالي',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'الحذف الناعم',
    created_by_user_id INT UNSIGNED NULL COMMENT 'أنشأه',
    updated_by_user_id INT UNSIGNED NULL COMMENT 'حدّثه',
    
    UNIQUE KEY uk_current (is_current),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأعوام الدراسية';

-- -----------------------------------------------------------------------------
-- 3. جدول الفصول الدراسية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS semesters (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    name_ar VARCHAR(50) NOT NULL COMMENT 'الفصل الأول / الثاني',
    semester_number TINYINT UNSIGNED NOT NULL COMMENT '1 أو 2',
    start_date DATE NULL,
    end_date DATE NULL,
    is_current BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- التدقيق
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'الحذف الناعم',
    
    -- القيود
    CHECK (semester_number BETWEEN 1 AND 2),
    UNIQUE KEY uk_year_semester (academic_year_id, semester_number),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الفصول الدراسية';

-- -----------------------------------------------------------------------------
-- 4. جدول الأشهر الأكاديمية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS academic_months (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    semester_id INT UNSIGNED NOT NULL,
    name_ar VARCHAR(30) NOT NULL COMMENT 'الشهر الأول / الثاني ...',
    month_number TINYINT UNSIGNED NOT NULL COMMENT '1-5',
    hijri_month_name VARCHAR(20) NULL COMMENT 'اسم الشهر الهجري',
    start_date DATE NULL,
    end_date DATE NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    UNIQUE KEY uk_semester_month (semester_id, month_number),
    FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الأشهر الأكاديمية';

-- -----------------------------------------------------------------------------
-- 5. جدول المستويات/الصفوف
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grade_levels (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL COMMENT 'الصف الأول / الثاني ...',
    name_en VARCHAR(50) NULL,
    grade_number TINYINT UNSIGNED NOT NULL COMMENT '1-12',
    stage ENUM('ابتدائي', 'إعدادي', 'ثانوي') NOT NULL,
    period_id TINYINT UNSIGNED NULL COMMENT 'فترة الصف',
    is_active BOOLEAN DEFAULT TRUE,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_grade (grade_number, stage),
    INDEX idx_stage (stage),
    FOREIGN KEY (period_id) REFERENCES lookup_periods(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المستويات والصفوف الدراسية';

-- إدخال الصفوف الأساسية
INSERT INTO grade_levels (name_ar, grade_number, stage, sort_order) VALUES
('الصف الأول', 1, 'ابتدائي', 1),
('الصف الثاني', 2, 'ابتدائي', 2),
('الصف الثالث', 3, 'ابتدائي', 3),
('الصف الرابع', 4, 'ابتدائي', 4),
('الصف الخامس', 5, 'ابتدائي', 5),
('الصف السادس', 6, 'ابتدائي', 6),
('الصف السابع', 7, 'إعدادي', 7),
('الصف الثامن', 8, 'إعدادي', 8),
('الصف التاسع', 9, 'إعدادي', 9),
('الصف الأول ثانوي', 10, 'ثانوي', 10),
('الصف الثاني ثانوي', 11, 'ثانوي', 11),
('الصف الثالث ثانوي', 12, 'ثانوي', 12);

-- -----------------------------------------------------------------------------
-- 6. جدول الفصول/الشعب
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS classrooms (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    grade_level_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    name_ar VARCHAR(50) NOT NULL COMMENT 'أ، ب، ج أو 1، 2، 3',
    classroom_number VARCHAR(10) NULL COMMENT 'رقم الغرفة',
    building_id TINYINT UNSIGNED NULL COMMENT 'المبنى',
    floor TINYINT UNSIGNED NULL COMMENT 'الدور',
    capacity TINYINT UNSIGNED NULL COMMENT 'السعة القصوى',
    supervisor_id INT UNSIGNED NULL COMMENT 'مربي/رائد الصف',
    period_id TINYINT UNSIGNED NULL COMMENT 'الفترة',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_classroom (grade_level_id, academic_year_id, name_ar),
    INDEX idx_grade (grade_level_id),
    INDEX idx_year (academic_year_id),
    INDEX idx_supervisor (supervisor_id),
    INDEX idx_building (building_id),
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (period_id) REFERENCES lookup_periods(id),
    FOREIGN KEY (building_id) REFERENCES lookup_buildings(id)
    -- FK supervisor_id سيُربط لاحقاً مع employees
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='الفصول والشعب الدراسية';

-- -----------------------------------------------------------------------------
-- 7. جدول المواد الدراسية
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NULL,
    code VARCHAR(20) NULL UNIQUE COMMENT 'رمز المادة',
    subject_type ENUM('أساسي', 'اختياري', 'نشاط') DEFAULT 'أساسي',
    is_graded BOOLEAN DEFAULT TRUE COMMENT 'لها درجات',
    max_grade DECIMAL(5,2) DEFAULT 100.00 COMMENT 'الدرجة القصوى',
    is_active BOOLEAN DEFAULT TRUE,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_type (subject_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='المواد الدراسية';

-- إدخال المواد الأساسية
INSERT INTO subjects (name_ar, code, subject_type, sort_order) VALUES
('القرآن الكريم', 'QURAN', 'أساسي', 1),
('التربية الإسلامية', 'ISL', 'أساسي', 2),
('اللغة العربية', 'ARB', 'أساسي', 3),
('اللغة الإنجليزية', 'ENG', 'أساسي', 4),
('الرياضيات', 'MATH', 'أساسي', 5),
('العلوم', 'SCI', 'أساسي', 6),
('الفيزياء', 'PHY', 'أساسي', 7),
('الكيمياء', 'CHM', 'أساسي', 8),
('الأحياء', 'BIO', 'أساسي', 9),
('الدراسات الاجتماعية', 'SOC', 'أساسي', 10),
('التاريخ', 'HIS', 'أساسي', 11),
('الجغرافيا', 'GEO', 'أساسي', 12),
('التربية الوطنية', 'NAT', 'أساسي', 13),
('الحاسوب', 'CS', 'أساسي', 14),
('التربية الفنية', 'ART', 'نشاط', 15),
('التربية الرياضية', 'PE', 'نشاط', 16);

-- -----------------------------------------------------------------------------
-- 8. جدول ربط المواد بالصفوف
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grade_subjects (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    grade_level_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    weekly_periods TINYINT UNSIGNED DEFAULT 1 COMMENT 'عدد الحصص الأسبوعية',
    semester_id INT UNSIGNED NULL COMMENT 'NULL = كل الفصول',
    is_required BOOLEAN DEFAULT TRUE COMMENT 'إلزامية',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_grade_subject (grade_level_id, subject_id, semester_id),
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='ربط المواد بالصفوف';

-- ═══════════════════════════════════════════════════════════════════════════════
-- نهاية الجزء 2: النواة الأكاديمية
-- ═══════════════════════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  الملخص:                                                                     ║
-- ║  - schools: بيانات المدرسة                                                   ║
-- ║  - academic_years: الأعوام الدراسية                                          ║
-- ║  - semesters: الفصول الدراسية                                                ║
-- ║  - academic_months: الأشهر الأكاديمية                                        ║
-- ║  - grade_levels: الصفوف والمستويات                                           ║
-- ║  - classrooms: الفصول والشعب                                                 ║
-- ║  - subjects: المواد الدراسية                                                 ║
-- ║  - grade_subjects: ربط المواد بالصفوف                                        ║
-- ║  ─────────────────────────────────────────────                               ║
-- ║  المجموع: 8 جداول                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- -----------------------------------------------------------------------------
-- 9. (ملحق) إضافة قيود التقويم (FK) - تنفيذ متأخر لتفادي الاعتمادية
-- -----------------------------------------------------------------------------
-- تم إضافة هذا القيد هنا لأن calendar_master موجود في الملف 01 والجدول academic_years في الملف 02
-- وهذا الملف يتم تنفيذه بعد الملف 01
ALTER TABLE calendar_master 
ADD CONSTRAINT fk_calendar_academic_year 
FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL;
