-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 5: النتائج — الفصل + العام + النقل (Results)                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (exam_timetable FK + exam_type_id FK + all ENUMs removed)
-- الاعتمادات: DDL_POLICIES, DDL_MONTHLY, System 02, System 04, System 08

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. نتيجة الفصل الدراسي (Semester Grades)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS semester_grades (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    semester_id INT UNSIGNED NOT NULL,

    -- مكونات نتيجة الفصل
    semester_work_total DECIMAL(6,2) DEFAULT 0 COMMENT 'مجموع أعمال الفصل (من المحصلات الشهرية)',
    final_exam_score DECIMAL(6,2) DEFAULT NULL COMMENT 'درجة الاختبار النهائي',

    -- الإجمالي
    semester_total DECIMAL(6,2) GENERATED ALWAYS AS (
        semester_work_total + IFNULL(final_exam_score, 0)
    ) STORED COMMENT 'إجمالي الفصل (أعمال + نهائي)',

    -- الحالة
    grading_status_id TINYINT UNSIGNED DEFAULT 1 COMMENT 'مسودة/مراجعة/معتمد',
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_semester_grade (enrollment_id, subject_id, semester_id),
    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (semester_id) REFERENCES semesters(id),
    FOREIGN KEY (grading_status_id) REFERENCES lookup_grading_statuses(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='نتيجة الفصل الدراسي لكل مادة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. حالات نتيجة المادة السنوية (Lookup)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_annual_statuses (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='حالات نتيجة المادة (ناجح/راسب/مكمل/محروم)';

INSERT INTO lookup_annual_statuses (name_ar, code) VALUES
('ناجح', 'PASS'),
('راسب', 'FAIL'),
('مكمل', 'MAKEUP'),
('محروم بسبب الغياب', 'DEPRIVED')
ON DUPLICATE KEY UPDATE
    name_ar = VALUES(name_ar);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. نتيجة العام لكل مادة (Annual Grades)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS annual_grades (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    subject_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,

    -- نتائج الفصلين
    semester1_total DECIMAL(6,2) DEFAULT 0.00 COMMENT 'إجمالي الفصل الأول',
    semester2_total DECIMAL(6,2) DEFAULT 0.00 COMMENT 'إجمالي الفصل الثاني',

    -- المجموع السنوي
    annual_total DECIMAL(7,2) GENERATED ALWAYS AS (
        semester1_total + semester2_total
    ) STORED COMMENT 'مجموع العام',

    -- النسبة المئوية
    annual_percentage DECIMAL(5,2) NULL COMMENT 'النسبة المئوية للمادة',

    -- الحالة
    final_status_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'ناجح/راسب/مكمل/محروم',

    -- الحوكمة
    grading_status_id TINYINT UNSIGNED DEFAULT 1 COMMENT 'مسودة/مراجعة/معتمد',
    calculated_at TIMESTAMP NULL COMMENT 'تاريخ الحساب الآلي',
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_annual_grade (enrollment_id, subject_id, academic_year_id),
    INDEX idx_annual_status (final_status_id),

    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (final_status_id) REFERENCES lookup_annual_statuses(id),
    FOREIGN KEY (grading_status_id) REFERENCES lookup_grading_statuses(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='نتيجة العام لكل مادة';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. قرارات النقل/الإعادة (Lookup)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_promotion_decisions (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_ar VARCHAR(80) NOT NULL,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قرارات النقل والإعادة';

INSERT INTO lookup_promotion_decisions (name_ar, code) VALUES
('ينقل للصف التالي', 'PROMOTED'),
('يعيد السنة', 'RETAINED'),
('يُفصل', 'DISMISSED'),
('ينقل بشروط (مكمل)', 'CONDITIONAL')
ON DUPLICATE KEY UPDATE
    name_ar = VALUES(name_ar);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. قواعد مخرجات النتائج (قابلة للتخصيص لكل عام/صف)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS grading_outcome_rules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    academic_year_id INT UNSIGNED NOT NULL,
    grade_level_id INT UNSIGNED NOT NULL,

    promoted_max_failed_subjects TINYINT UNSIGNED NOT NULL DEFAULT 0
        COMMENT 'إذا كان عدد الرسوب <= هذا الحد فالقرار: ناجح',
    conditional_max_failed_subjects TINYINT UNSIGNED NOT NULL DEFAULT 2
        COMMENT 'إذا كان عدد الرسوب <= هذا الحد فالقرار: مشروط',

    conditional_decision_id TINYINT UNSIGNED NOT NULL DEFAULT 4,
    retained_decision_id TINYINT UNSIGNED NOT NULL DEFAULT 2,

    tie_break_strategy ENUM('PERCENTAGE_ONLY', 'PERCENTAGE_THEN_TOTAL', 'PERCENTAGE_THEN_NAME')
        NOT NULL DEFAULT 'PERCENTAGE_THEN_NAME',

    is_active BOOLEAN DEFAULT TRUE,
    created_by_user_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    CHECK (conditional_max_failed_subjects >= promoted_max_failed_subjects),
    UNIQUE KEY uk_outcome_rule (academic_year_id, grade_level_id),

    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (grade_level_id) REFERENCES grade_levels(id),
    FOREIGN KEY (conditional_decision_id) REFERENCES lookup_promotion_decisions(id),
    FOREIGN KEY (retained_decision_id) REFERENCES lookup_promotion_decisions(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='قواعد تخصيص قرار النقل وكسر التعادل';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. النتيجة النهائية الشاملة (Annual Result)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS annual_result (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,

    -- المجاميع
    total_all_subjects DECIMAL(8,2) DEFAULT 0.00 COMMENT 'مجموع كل المواد',
    max_possible_total DECIMAL(8,2) DEFAULT 0.00 COMMENT 'الدرجة العظمى الكلية',
    percentage DECIMAL(5,2) DEFAULT 0.00 COMMENT 'النسبة المئوية العامة',

    -- الترتيب
    rank_in_class SMALLINT UNSIGNED NULL COMMENT 'ترتيب الطالب في فصله',
    rank_in_grade SMALLINT UNSIGNED NULL COMMENT 'ترتيب الطالب في صفه (كل الشعب)',

    -- القرار
    passed_subjects_count TINYINT UNSIGNED DEFAULT 0 COMMENT 'عدد المواد الناجح فيها',
    failed_subjects_count TINYINT UNSIGNED DEFAULT 0 COMMENT 'عدد المواد الراسب فيها',
    promotion_decision_id TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'ينقل/يعيد/يفصل/مشروط',

    -- الحوكمة
    grading_status_id TINYINT UNSIGNED DEFAULT 1 COMMENT 'مسودة/مراجعة/معتمد',
    approved_by_user_id INT UNSIGNED NULL,
    approved_at TIMESTAMP NULL,
    notes TEXT NULL COMMENT 'ملاحظات إدارية',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_annual_result (enrollment_id, academic_year_id),
    INDEX idx_promotion (promotion_decision_id),

    FOREIGN KEY (enrollment_id) REFERENCES student_enrollments(id),
    FOREIGN KEY (academic_year_id) REFERENCES academic_years(id),
    FOREIGN KEY (promotion_decision_id) REFERENCES lookup_promotion_decisions(id),
    FOREIGN KEY (grading_status_id) REFERENCES lookup_grading_statuses(id),
    FOREIGN KEY (approved_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='النتيجة النهائية الشاملة (المجموع + النسبة + الترتيب + قرار النقل)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. View: ترتيب الطلاب داخل الصف
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_sgas_class_ranking AS
SELECT
    ar.enrollment_id,
    se.student_id,
    se.classroom_id,
    ar.academic_year_id,
    ar.total_all_subjects,
    ar.percentage,
    ar.rank_in_class,
    ar.rank_in_grade,
    ar.promotion_decision_id,
    lpd.name_ar AS promotion_decision_name,
    ar.grading_status_id,
    lgs.name_ar AS grading_status_name
FROM annual_result ar
JOIN student_enrollments se ON ar.enrollment_id = se.id
JOIN lookup_promotion_decisions lpd ON ar.promotion_decision_id = lpd.id
JOIN lookup_grading_statuses lgs ON ar.grading_status_id = lgs.id
ORDER BY ar.percentage DESC, ar.total_all_subjects DESC, ar.rank_in_class ASC;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. Procedure: حساب semester_work_total آلياً من المحصلات الشهرية
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_calculate_semester_totals(
    IN p_semester_id INT,
    IN p_subject_id INT,
    IN p_classroom_id INT
)
BEGIN
    INSERT INTO semester_grades (enrollment_id, subject_id, semester_id, semester_work_total)
    SELECT
        mg.enrollment_id,
        mg.subject_id,
        p_semester_id,
        SUM(
            mg.attendance_score
            + mg.homework_score
            + mg.activity_score
            + mg.contribution_score
            + mg.custom_components_score
            + mg.exam_score
        ) AS total
    FROM monthly_grades mg
    JOIN academic_months am ON mg.month_id = am.id
    WHERE am.semester_id = p_semester_id
      AND mg.subject_id = p_subject_id
      AND mg.enrollment_id IN (
          SELECT id
          FROM student_enrollments
          WHERE classroom_id = p_classroom_id
            AND is_active = TRUE
      )
    GROUP BY mg.enrollment_id, mg.subject_id
    ON DUPLICATE KEY UPDATE
        semester_work_total = VALUES(semester_work_total),
        updated_at = CURRENT_TIMESTAMP;
END//

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. Procedure: حساب النتيجة السنوية + القرار + الترتيب
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE PROCEDURE sp_calculate_annual_results(
    IN p_academic_year_id INT,
    IN p_classroom_id INT
)
BEGIN
    DECLARE v_grade_level_id INT;
    DECLARE v_promoted_decision_id TINYINT UNSIGNED DEFAULT 1;
    DECLARE v_promoted_max_failed TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_conditional_max_failed TINYINT UNSIGNED DEFAULT 2;
    DECLARE v_conditional_decision_id TINYINT UNSIGNED DEFAULT 4;
    DECLARE v_retained_decision_id TINYINT UNSIGNED DEFAULT 2;
    DECLARE v_tie_break_strategy VARCHAR(30) DEFAULT 'PERCENTAGE_THEN_NAME';

    SELECT c.grade_level_id
    INTO v_grade_level_id
    FROM classrooms c
    WHERE c.id = p_classroom_id
    LIMIT 1;

    SELECT id INTO v_promoted_decision_id
    FROM lookup_promotion_decisions
    WHERE code = 'PROMOTED'
    LIMIT 1;

    SELECT id INTO v_conditional_decision_id
    FROM lookup_promotion_decisions
    WHERE code = 'CONDITIONAL'
    LIMIT 1;

    SELECT id INTO v_retained_decision_id
    FROM lookup_promotion_decisions
    WHERE code = 'RETAINED'
    LIMIT 1;

    SELECT
        gor.promoted_max_failed_subjects,
        gor.conditional_max_failed_subjects,
        gor.conditional_decision_id,
        gor.retained_decision_id,
        gor.tie_break_strategy
    INTO
        v_promoted_max_failed,
        v_conditional_max_failed,
        v_conditional_decision_id,
        v_retained_decision_id,
        v_tie_break_strategy
    FROM grading_outcome_rules gor
    WHERE gor.academic_year_id = p_academic_year_id
      AND gor.grade_level_id = v_grade_level_id
      AND gor.is_active = TRUE
    LIMIT 1;

    -- 1) annual_grades
    INSERT INTO annual_grades (
        enrollment_id, subject_id, academic_year_id,
        semester1_total, semester2_total, annual_percentage,
        final_status_id, calculated_at
    )
    SELECT
        t.enrollment_id,
        t.subject_id,
        p_academic_year_id,
        t.semester1_total,
        t.semester2_total,
        CASE
            WHEN ((t.base_max_once + t.custom_max_once) * 2) > 0
                THEN ((t.semester1_total + t.semester2_total) / ((t.base_max_once + t.custom_max_once) * 2)) * 100
            ELSE 0
        END AS annual_percentage,
        CASE
            WHEN
                CASE
                    WHEN ((t.base_max_once + t.custom_max_once) * 2) > 0
                        THEN ((t.semester1_total + t.semester2_total) / ((t.base_max_once + t.custom_max_once) * 2)) * 100
                    ELSE 0
                END >= t.passing_score
            THEN 1
            ELSE 2
        END AS final_status_id,
        CURRENT_TIMESTAMP
    FROM (
        SELECT
            se.id AS enrollment_id,
            sg.subject_id,
            SUM(CASE WHEN sem.semester_number = 1 THEN sg.semester_total ELSE 0 END) AS semester1_total,
            SUM(CASE WHEN sem.semester_number = 2 THEN sg.semester_total ELSE 0 END) AS semester2_total,
            COALESCE(MAX(gp.passing_score), 50.00) AS passing_score,
            COALESCE(MAX(
                COALESCE(gp.max_exam_score, 0)
                + COALESCE(gp.max_homework_score, 0)
                + COALESCE(gp.max_attendance_score, 0)
                + COALESCE(gp.max_activity_score, 0)
                + COALESCE(gp.max_contribution_score, 0)
            ), 0) AS base_max_once,
            COALESCE(MAX((
                SELECT COALESCE(SUM(gpcc.max_score), 0)
                FROM grading_policy_custom_components gpcc
                WHERE gpcc.policy_id = gp.id
                  AND gpcc.is_active = TRUE
                  AND gpcc.include_in_semester = TRUE
            )), 0) AS custom_max_once
        FROM student_enrollments se
        JOIN semester_grades sg ON sg.enrollment_id = se.id
        JOIN semesters sem ON sem.id = sg.semester_id
        LEFT JOIN grading_policies gp ON gp.academic_year_id = p_academic_year_id
            AND gp.grade_level_id = v_grade_level_id
            AND gp.subject_id = sg.subject_id
            AND gp.exam_type_id = 1 -- MONTHLY
        WHERE se.classroom_id = p_classroom_id
          AND se.is_active = TRUE
        GROUP BY se.id, sg.subject_id
    ) t
    ON DUPLICATE KEY UPDATE
        semester1_total = VALUES(semester1_total),
        semester2_total = VALUES(semester2_total),
        annual_percentage = VALUES(annual_percentage),
        final_status_id = VALUES(final_status_id),
        calculated_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;

    -- 2) annual_result
    INSERT INTO annual_result (
        enrollment_id, academic_year_id,
        total_all_subjects, max_possible_total, percentage,
        passed_subjects_count, failed_subjects_count,
        promotion_decision_id
    )
    SELECT
        ag.enrollment_id,
        p_academic_year_id,
        SUM(ag.annual_total) AS total_all,
        SUM(
            (
                COALESCE(gp.max_exam_score, 0)
                + COALESCE(gp.max_homework_score, 0)
                + COALESCE(gp.max_attendance_score, 0)
                + COALESCE(gp.max_activity_score, 0)
                + COALESCE(gp.max_contribution_score, 0)
                + COALESCE(gpcc_sum.max_custom_score, 0)
            ) * 2
        ) AS max_total,
        COALESCE(
            (
                SUM(ag.annual_total) / NULLIF(
                    SUM(
                        (
                            COALESCE(gp.max_exam_score, 0)
                            + COALESCE(gp.max_homework_score, 0)
                            + COALESCE(gp.max_attendance_score, 0)
                            + COALESCE(gp.max_activity_score, 0)
                            + COALESCE(gp.max_contribution_score, 0)
                            + COALESCE(gpcc_sum.max_custom_score, 0)
                        ) * 2
                    ),
                    0
                )
            ) * 100,
            0
        ) AS pct,
        SUM(CASE WHEN ag.final_status_id = 1 THEN 1 ELSE 0 END) AS passed_count,
        SUM(CASE WHEN ag.final_status_id != 1 THEN 1 ELSE 0 END) AS failed_count,
        CASE
            WHEN SUM(CASE WHEN ag.final_status_id != 1 THEN 1 ELSE 0 END) <= v_promoted_max_failed THEN v_promoted_decision_id
            WHEN SUM(CASE WHEN ag.final_status_id != 1 THEN 1 ELSE 0 END) <= v_conditional_max_failed THEN v_conditional_decision_id
            ELSE v_retained_decision_id
        END AS decision_id
    FROM annual_grades ag
    JOIN student_enrollments se ON ag.enrollment_id = se.id
    LEFT JOIN grading_policies gp ON gp.academic_year_id = p_academic_year_id
        AND gp.grade_level_id = v_grade_level_id
        AND gp.subject_id = ag.subject_id
        AND gp.exam_type_id = 1 -- MONTHLY
    LEFT JOIN (
        SELECT
            gpcc.policy_id,
            SUM(gpcc.max_score) AS max_custom_score
        FROM grading_policy_custom_components gpcc
        WHERE gpcc.is_active = TRUE
          AND gpcc.include_in_semester = TRUE
        GROUP BY gpcc.policy_id
    ) gpcc_sum ON gpcc_sum.policy_id = gp.id
    WHERE ag.academic_year_id = p_academic_year_id
      AND se.classroom_id = p_classroom_id
      AND se.is_active = TRUE
    GROUP BY ag.enrollment_id
    ON DUPLICATE KEY UPDATE
        total_all_subjects = VALUES(total_all_subjects),
        max_possible_total = VALUES(max_possible_total),
        percentage = VALUES(percentage),
        passed_subjects_count = VALUES(passed_subjects_count),
        failed_subjects_count = VALUES(failed_subjects_count),
        promotion_decision_id = VALUES(promotion_decision_id),
        updated_at = CURRENT_TIMESTAMP;

    -- 3) الترتيب داخل الفصل (مع كسر تعادل قابل للتخصيص)
    SET @rank_class := 0;
    UPDATE annual_result ar
    JOIN (
        SELECT
            ar2.id,
            @rank_class := @rank_class + 1 AS calculated_rank
        FROM annual_result ar2
        JOIN student_enrollments se2 ON ar2.enrollment_id = se2.id
        JOIN students st2 ON se2.student_id = st2.id
        WHERE se2.classroom_id = p_classroom_id
          AND ar2.academic_year_id = p_academic_year_id
        ORDER BY
            ar2.percentage DESC,
            CASE
                WHEN v_tie_break_strategy IN ('PERCENTAGE_THEN_TOTAL', 'PERCENTAGE_THEN_NAME')
                    THEN ar2.total_all_subjects
                ELSE NULL
            END DESC,
            CASE
                WHEN v_tie_break_strategy = 'PERCENTAGE_THEN_NAME'
                    THEN st2.full_name
                ELSE NULL
            END ASC,
            ar2.id ASC
    ) ranked ON ar.id = ranked.id
    SET ar.rank_in_class = ranked.calculated_rank;

    -- 4) الترتيب على مستوى الصف (كل الشعب)
    SET @rank_grade := 0;
    UPDATE annual_result ar
    JOIN (
        SELECT
            ar2.id,
            @rank_grade := @rank_grade + 1 AS calculated_rank
        FROM annual_result ar2
        JOIN student_enrollments se2 ON ar2.enrollment_id = se2.id
        JOIN classrooms c2 ON se2.classroom_id = c2.id
        JOIN students st2 ON se2.student_id = st2.id
        WHERE ar2.academic_year_id = p_academic_year_id
          AND c2.academic_year_id = p_academic_year_id
          AND c2.grade_level_id = v_grade_level_id
        ORDER BY
            ar2.percentage DESC,
            CASE
                WHEN v_tie_break_strategy IN ('PERCENTAGE_THEN_TOTAL', 'PERCENTAGE_THEN_NAME')
                    THEN ar2.total_all_subjects
                ELSE NULL
            END DESC,
            CASE
                WHEN v_tie_break_strategy = 'PERCENTAGE_THEN_NAME'
                    THEN st2.full_name
                ELSE NULL
            END ASC,
            ar2.id ASC
    ) ranked_grade ON ar.id = ranked_grade.id
    SET ar.rank_in_grade = ranked_grade.calculated_rank;
END//

-- ═══════════════════════════════════════════════════════════════════════════════
-- 10. Procedure: سحب درجة الاختبار النهائي إلى semester_grades آلياً
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE PROCEDURE sp_fill_final_exam_score(
    IN p_semester_id INT,
    IN p_classroom_id INT
)
BEGIN
    DECLARE v_grade_level_id INT;
    DECLARE v_academic_year_id INT;

    SELECT c.grade_level_id, c.academic_year_id
    INTO v_grade_level_id, v_academic_year_id
    FROM classrooms c
    WHERE c.id = p_classroom_id
    LIMIT 1;

    UPDATE semester_grades sg
    JOIN student_enrollments se ON sg.enrollment_id = se.id
    JOIN (
        SELECT
            ses.enrollment_id,
            et.subject_id,
            SUM(ses.score) AS total_final_score,
            SUM(et.max_score) AS total_final_max
        FROM student_exam_scores ses
        JOIN exam_timetable et ON ses.exam_timetable_id = et.id
        JOIN exam_periods ep ON et.exam_period_id = ep.id
        WHERE ep.exam_type_id = 3 -- FINAL
          AND ep.semester_id = p_semester_id
          AND ep.academic_year_id = v_academic_year_id
          AND et.grade_level_id = v_grade_level_id
          AND ses.is_present = TRUE
        GROUP BY ses.enrollment_id, et.subject_id
    ) final_data ON final_data.enrollment_id = sg.enrollment_id
                 AND final_data.subject_id = sg.subject_id
    LEFT JOIN grading_policies gp_final ON gp_final.academic_year_id = v_academic_year_id
        AND gp_final.grade_level_id = v_grade_level_id
        AND gp_final.subject_id = sg.subject_id
        AND gp_final.exam_type_id = 3 -- FINAL
    SET sg.final_exam_score = CASE
            WHEN final_data.total_final_max > 0
                THEN (final_data.total_final_score / final_data.total_final_max)
                     * COALESCE(gp_final.max_exam_score, final_data.total_final_max)
            ELSE 0
        END,
        sg.updated_at = CURRENT_TIMESTAMP
    WHERE sg.semester_id = p_semester_id
      AND se.classroom_id = p_classroom_id
      AND se.is_active = TRUE;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_RESULTS v4.0: النتائج + exam_timetable + exam_type_id FK' AS message;
