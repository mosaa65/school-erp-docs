-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                     نظام إدارة المدرسة المتكامل                              ║
-- ║                School Management System Database                              ║
-- ║                                                                               ║
-- ║  الجزء 6: الإدارة والعمليات (Administration & Operations)                    ║
-- ║  المسؤول: عماد الجماعي (المهندس المشرف)                                       ║
-- ║  الإصدار: 2.0 (Refactored for Governance)                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-01-16

-- =============================================================================
-- القسم 1: الاجتماعات والقرارات (Meetings & Governance)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meetings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meeting_type_id TINYINT UNSIGNED NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL,
    subject VARCHAR(200) NOT NULL,
    meeting_date DATE NOT NULL,
    start_time TIME NULL,
    end_time TIME NULL,
    location_id TINYINT UNSIGNED NULL COMMENT 'FK to lookup_facility_types',
    notes TEXT NULL,
    minutes_content TEXT NULL COMMENT 'محضر الاجتماع',
    minutes_approved_by INT UNSIGNED NULL COMMENT 'FK to users',
    
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (meeting_type_id) REFERENCES lookup_meeting_types(id),
    FOREIGN KEY (status_id) REFERENCES lookup_meeting_statuses(id),
    FOREIGN KEY (location_id) REFERENCES lookup_facility_types(id),
    FOREIGN KEY (minutes_approved_by) REFERENCES users(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الاجتماعات المدرسية المحوكمة';

CREATE TABLE IF NOT EXISTS meeting_attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meeting_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL COMMENT 'FK to lookup_attendance_statuses',
    excuse_details TEXT NULL,
    
    UNIQUE KEY uk_attendance (meeting_id, employee_id),
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (status_id) REFERENCES lookup_attendance_statuses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='حضور الاجتماعات';

CREATE TABLE IF NOT EXISTS meeting_decisions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meeting_id INT UNSIGNED NOT NULL,
    decision_text TEXT NOT NULL,
    assigned_employee_id INT UNSIGNED NULL COMMENT 'المسؤول عن التنفيذ',
    due_date DATE NULL,
    execution_status ENUM('PENDING', 'IN_PROGRESS', 'EXECUTE', 'CANCELLED') DEFAULT 'PENDING',
    execution_notes TEXT NULL,
    
    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='قرارات الاجتماعات ومتابعة تنفيذها';

-- =============================================================================
-- القسم 2: المسابقات والأنشطة (Competitions & Talent)
-- =============================================================================

CREATE TABLE IF NOT EXISTS competitions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id TINYINT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    evaluation_criteria JSON NULL COMMENT 'معايير التقييم ككائنات برمجية',
    budget DECIMAL(10,2) DEFAULT 0.00,
    supervisor_employee_id INT UNSIGNED,
    
    FOREIGN KEY (category_id) REFERENCES lookup_competition_categories(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (supervisor_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='المسابقات والفعاليات';

CREATE TABLE IF NOT EXISTS competition_participants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    competition_id INT UNSIGNED NOT NULL,
    participant_type ENUM('STUDENT', 'EMPLOYEE', 'CLASS') NOT NULL,
    student_id INT UNSIGNED NULL,
    employee_id INT UNSIGNED NULL,
    classroom_id INT UNSIGNED NULL,
    
    initial_score DECIMAL(5,2) DEFAULT 0,
    rank_position TINYINT UNSIGNED NULL,
    is_winner BOOLEAN DEFAULT FALSE,
    prize_details VARCHAR(255),
    
    FOREIGN KEY (competition_id) REFERENCES competitions(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='المشاركين والنتائج في المسابقات';

-- =============================================================================
-- القسم 3: العمليات والصيانة (O&M)
-- =============================================================================

CREATE TABLE IF NOT EXISTS maintenance_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    facility_id TINYINT UNSIGNED NOT NULL,
    description TEXT NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reported_by_employee_id INT UNSIGNED NOT NULL,
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT') DEFAULT 'MEDIUM',
    status_id TINYINT UNSIGNED NOT NULL COMMENT 'FK to lookup_maintenance_statuses',
    
    FOREIGN KEY (facility_id) REFERENCES lookup_facility_types(id),
    FOREIGN KEY (reported_by_employee_id) REFERENCES employees(id),
    FOREIGN KEY (status_id) REFERENCES lookup_maintenance_statuses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='طلبات الصيانة والإصلاح';

CREATE TABLE IF NOT EXISTS maintenance_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    request_id INT UNSIGNED NOT NULL,
    action_taken TEXT,
    completion_date DATE,
    cost DECIMAL(10,2) DEFAULT 0.00,
    contractor_name VARCHAR(150),
    verified_by_employee_id INT UNSIGNED,
    
    FOREIGN KEY (request_id) REFERENCES maintenance_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل تنفيذ الصيانة';

CREATE TABLE IF NOT EXISTS school_cleaning_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cleaning_date DATE NOT NULL,
    facility_id TINYINT UNSIGNED NOT NULL,
    cleaner_role_id TINYINT UNSIGNED NOT NULL COMMENT 'FK to lookup_job_roles',
    supervisor_employee_id INT UNSIGNED,
    score TINYINT COMMENT '1-10',
    violation_notes TEXT,
    
    FOREIGN KEY (facility_id) REFERENCES lookup_facility_types(id),
    FOREIGN KEY (cleaner_role_id) REFERENCES lookup_job_roles(id),
    FOREIGN KEY (supervisor_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل النظافة الفني';

-- =============================================================================
-- القسم 4: الزوار والعلاقات العامة
-- =============================================================================

CREATE TABLE IF NOT EXISTS visitor_logs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    visitor_name VARCHAR(150) NOT NULL,
    gender_id TINYINT UNSIGNED NOT NULL,
    visitor_source_id TINYINT UNSIGNED NOT NULL COMMENT 'FK to lookup_visitor_sources',
    position_title VARCHAR(100) NULL COMMENT 'الصفة',
    
    visit_purpose VARCHAR(255) NULL COMMENT 'الغرض من الزيارة',
    visit_reason TEXT NULL COMMENT 'سبب زيارته',
    
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    hijri_month_id TINYINT UNSIGNED NOT NULL,
    week_id TINYINT UNSIGNED NOT NULL,
    day_id TINYINT UNSIGNED NOT NULL,
    
    id_number VARCHAR(50) NULL,
    entry_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    exit_time TIMESTAMP NULL,
    hosted_by_employee_id INT UNSIGNED NOT NULL,
    
    is_documented_in_record BOOLEAN DEFAULT FALSE COMMENT 'وثق في سجل المدرسة',
    visit_outcome TEXT,
    
    FOREIGN KEY (gender_id) REFERENCES lookup_genders(id),
    FOREIGN KEY (visitor_source_id) REFERENCES lookup_visitor_sources(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (hijri_month_id) REFERENCES lookup_hijri_months(id),
    -- FOREIGN KEY (week_id) REFERENCES lookup_week_numbers(id), -- Add if needed
    FOREIGN KEY (day_id) REFERENCES lookup_days(id),
    FOREIGN KEY (hosted_by_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الزوار المطوّر (شامل متطلبات المدير)';

-- =============================================================================
-- القسم 5: الحوكمة والمشكلات (Governance & Incidents)
-- =============================================================================

CREATE TABLE IF NOT EXISTS gov_incidents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    target_type_id TINYINT UNSIGNED NOT NULL COMMENT 'موظف، طالب، أب، أم، إلخ',
    
    -- هوية الشخص (منفذ المشكلة أو المعني بها)
    entity_name VARCHAR(150) NOT NULL COMMENT 'الاسم (يدوياً أو من جداول النظام)',
    entity_id INT UNSIGNED NULL COMMENT 'رقم الشخص في قاعدة البيانات (اختياري للربط)',
    gender_id TINYINT UNSIGNED NOT NULL,
    
    -- التسلسل (1، 2، 3 حسب الشخص)
    incident_sequence SMALLINT UNSIGNED DEFAULT 1 COMMENT 'رقم المشكلة بالنسبة لهذا الشخص',
    
    -- الزمان
    incident_date DATE NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,
    hijri_month_id TINYINT UNSIGNED NOT NULL,
    week_id TINYINT UNSIGNED NOT NULL,
    day_id TINYINT UNSIGNED NOT NULL,
    
    -- تفاصيل المشكلة
    incident_title VARCHAR(200) NOT NULL COMMENT 'عنوان المشكلة',
    incident_description TEXT NOT NULL,
    adversaries_names TEXT NULL COMMENT 'من تشاكل معه',
    witnesses_names TEXT NULL COMMENT 'الشهود',
    
    -- الإجراءات والتوثيق
    actions_taken TEXT NULL,
    has_official_minutes BOOLEAN DEFAULT FALSE COMMENT 'حرر محضرها',
    minutes_file_id BIGINT UNSIGNED NULL COMMENT 'رابط لصورة المحضر من file_attachments',
    
    notes TEXT NULL,
    
    -- الحالة والقفل (حوكمة المدير)
    is_resolved BOOLEAN DEFAULT FALSE,
    manager_approval_at TIMESTAMP NULL,
    created_by_user_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_incident_lookup (target_type_id, incident_date),
    FOREIGN KEY (target_type_id) REFERENCES lookup_incident_target_types(id),
    FOREIGN KEY (gender_id) REFERENCES lookup_genders(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (hijri_month_id) REFERENCES lookup_hijri_months(id),
    FOREIGN KEY (day_id) REFERENCES lookup_days(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل المشكلات المركزي (حوكمة ورقابة)';

-- =============================================================================
-- القسم 5: مجلس الآباء (Parents Council - Formal)
-- =============================================================================

CREATE TABLE IF NOT EXISTS parents_council (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    formation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='مجلس الآباء الرسمي';

CREATE TABLE IF NOT EXISTS council_members (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    council_id INT UNSIGNED NOT NULL,
    guardian_id INT UNSIGNED NOT NULL,
    position ENUM('CHAIRMAN', 'VICE_CHAIRMAN', 'SECRETARY', 'MEMBER') DEFAULT 'MEMBER',
    join_date DATE,
    
    UNIQUE KEY uk_council_member (council_id, guardian_id),
    FOREIGN KEY (council_id) REFERENCES parents_council(id) ON DELETE CASCADE,
    FOREIGN KEY (guardian_id) REFERENCES guardians(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='أعضاء المجلس المربوطين بالنظام';

-- =============================================================================
-- القسم 6: الخطط والمتابعة (Planning & Performance)
-- =============================================================================

CREATE TABLE IF NOT EXISTS management_plans (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    task_title VARCHAR(200) NOT NULL,
    task_description TEXT,
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'MEDIUM',
    assigned_employee_id INT UNSIGNED,
    assigned_role_id TINYINT UNSIGNED COMMENT 'يمكن التكليف لدور وظيفي كامل',
    target_date DATE,
    completion_date DATE NULL,
    fail_reason TEXT NULL,
    
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(id),
    FOREIGN KEY (assigned_role_id) REFERENCES lookup_job_roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='خطط الإدارة والمتابعة';

-- =============================================================================
-- القسم 7: السلامة الصحية (School Health & Safety)
-- =============================================================================

CREATE TABLE IF NOT EXISTS first_aid_incidents (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    incident_date DATE NOT NULL,
    incident_time TIME,
    incident_type VARCHAR(100),
    description TEXT NOT NULL,
    action_taken TEXT,
    executor_employee_id INT UNSIGNED NOT NULL COMMENT 'المسعف المسؤول',
    parent_notified BOOLEAN DEFAULT FALSE,
    notified_at TIMESTAMP NULL,
    severity ENUM('MINOR', 'MODERATE', 'SEVERE') DEFAULT 'MINOR',
    
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (executor_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='سجل الإسعافات الأولية (قانوني)';

-- =============================================================================
-- القسم 8: فحص البنية التحتية (Facility Inspection)
-- =============================================================================

CREATE TABLE IF NOT EXISTS facility_inspections (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    facility_id TINYINT UNSIGNED NOT NULL,
    inspection_type_id TINYINT UNSIGNED,
    inspection_date DATE NOT NULL,
    inspector_id INT UNSIGNED NOT NULL,
    overall_score TINYINT COMMENT '1-100',
    critical_findings TEXT,
    
    FOREIGN KEY (facility_id) REFERENCES lookup_facility_types(id),
    FOREIGN KEY (inspector_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='فحص المرافق';

-- =============================================================================
-- القسم 9: الأنشطة المدرسية الإضافية (Broadcast)
-- =============================================================================

CREATE TABLE IF NOT EXISTS morning_broadcast (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    broadcast_date DATE NOT NULL,
    title VARCHAR(200),
    responsible_classroom_id INT UNSIGNED,
    supervisor_employee_id INT UNSIGNED,
    performance_rating TINYINT COMMENT '1-5 Stars',
    notes TEXT,
    FOREIGN KEY (responsible_classroom_id) REFERENCES classrooms(id),
    FOREIGN KEY (supervisor_employee_id) REFERENCES employees(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='الإذاعة الصباحية';

CREATE TABLE IF NOT EXISTS broadcast_items (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    broadcast_id INT UNSIGNED NOT NULL,
    student_id INT UNSIGNED NOT NULL,
    item_type VARCHAR(100) COMMENT 'قرآن، حديث، كلمة...',
    performance_score DECIMAL(3,1),
    
    FOREIGN KEY (broadcast_id) REFERENCES morning_broadcast(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='تقييم فقرات الإذاعة';

-- ═══════════════════════════════════════════════════════════════════════════════

-- -----------------------------------------------------------------------------
-- 10. (ملحق) Views التقويم التشغيلية (Admin)
-- -----------------------------------------------------------------------------

-- View: تقويم الاجتماعات
CREATE OR REPLACE VIEW v_meetings_calendar AS 
SELECT  
   m.id, m.subject, lmt.name_ar AS meeting_type, 
   m.meeting_date, 
   cm.hijri_date, cm.day_name_ar, 
   m.start_time, m.end_time, 
   lft.name_ar AS location, 
   lms.name_ar AS status 
FROM meetings m 
LEFT JOIN calendar_master cm ON m.meeting_date = cm.gregorian_date 
LEFT JOIN lookup_meeting_types lmt ON m.meeting_type_id = lmt.id 
LEFT JOIN lookup_facility_types lft ON m.location_id = lft.id 
LEFT JOIN lookup_meeting_statuses lms ON m.status_id = lms.id;

-- View: تقويم الفحص والصيانة
CREATE OR REPLACE VIEW v_inspections_calendar AS 
SELECT  
   fi.id, fi.inspection_date, 
   lft.name_ar AS facility, 
   e.full_name AS inspector, 
   fi.overall_score, 
   cm.hijri_date 
FROM facility_inspections fi 
LEFT JOIN calendar_master cm ON fi.inspection_date = cm.gregorian_date 
LEFT JOIN lookup_facility_types lft ON fi.facility_id = lft.id 
LEFT JOIN employees e ON fi.inspector_id = e.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- نهاية الجزء 6: الإدارة والعمليات
-- ═══════════════════════════════════════════════════════════════════════════════
