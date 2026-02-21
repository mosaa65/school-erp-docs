-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 8: التقارير والاستعلامات (Reports & Queries)                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (lookup_grade_descriptions + exam_type_id FK)
-- الوصف: Views و Functions للتقارير مع دعم أوصاف التقديرات المرنة

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. جدول مرجعي: أوصاف التقديرات (§3.2 — بدل hardcoded في دالة)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS lookup_grade_descriptions (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    min_percentage DECIMAL(5,2) NOT NULL COMMENT 'الحد الأدنى للنسبة',
    max_percentage DECIMAL(5,2) NOT NULL DEFAULT 100 COMMENT 'الحد الأعلى للنسبة',
    name_ar VARCHAR(50) NOT NULL COMMENT 'الوصف بالعربية',
    name_en VARCHAR(50) NULL COMMENT 'الوصف بالإنجليزية',
    color_code VARCHAR(7) NULL COMMENT 'لون للعرض في الواجهة',
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE KEY uk_lgd_range (min_percentage, max_percentage),
    CHECK (max_percentage >= min_percentage),
    CHECK (min_percentage >= 0),
    CHECK (max_percentage <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='أوصاف التقديرات المرنة — قابلة للتخصيص';

INSERT INTO lookup_grade_descriptions (min_percentage, max_percentage, name_ar, name_en, color_code, sort_order)
SELECT src.min_percentage, src.max_percentage, src.name_ar, src.name_en, src.color_code, src.sort_order
FROM (
    SELECT 90.00 AS min_percentage, 100.00 AS max_percentage, 'ممتاز' AS name_ar, 'Excellent' AS name_en, '#2ecc71' AS color_code, 1 AS sort_order
    UNION ALL SELECT 80.00, 89.99, 'جيد جداً', 'Very Good', '#3498db', 2
    UNION ALL SELECT 65.00, 79.99, 'جيد', 'Good', '#f39c12', 3
    UNION ALL SELECT 50.00, 64.99, 'مقبول', 'Acceptable', '#e67e22', 4
    UNION ALL SELECT 0.00, 49.99, 'ضعيف', 'Weak', '#e74c3c', 5
) src
WHERE NOT EXISTS (
    SELECT 1
    FROM lookup_grade_descriptions lgd
    WHERE lgd.min_percentage = src.min_percentage
      AND lgd.max_percentage = src.max_percentage
);

UPDATE lookup_grade_descriptions lgd
JOIN (
    SELECT 90.00 AS min_percentage, 100.00 AS max_percentage, 'ممتاز' AS name_ar, 'Excellent' AS name_en, '#2ecc71' AS color_code, 1 AS sort_order
    UNION ALL SELECT 80.00, 89.99, 'جيد جداً', 'Very Good', '#3498db', 2
    UNION ALL SELECT 65.00, 79.99, 'جيد', 'Good', '#f39c12', 3
    UNION ALL SELECT 50.00, 64.99, 'مقبول', 'Acceptable', '#e67e22', 4
    UNION ALL SELECT 0.00, 49.99, 'ضعيف', 'Weak', '#e74c3c', 5
) src
ON lgd.min_percentage = src.min_percentage
AND lgd.max_percentage = src.max_percentage
SET
    lgd.name_ar = src.name_ar,
    lgd.name_en = src.name_en,
    lgd.color_code = src.color_code,
    lgd.sort_order = src.sort_order,
    lgd.is_active = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. دالة وصف التقدير (محدّثة — تقرأ من الجدول مع fallback)
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE FUNCTION fn_get_grade_description(p_percentage DECIMAL(5,2))
RETURNS VARCHAR(50) DETERMINISTIC
BEGIN
    DECLARE v_description VARCHAR(50);

    -- محاولة القراءة من الجدول المرن
    SELECT lgd.name_ar INTO v_description
    FROM lookup_grade_descriptions lgd
    WHERE lgd.is_active = TRUE
      AND p_percentage >= lgd.min_percentage
      AND p_percentage <= lgd.max_percentage
    ORDER BY lgd.sort_order
    LIMIT 1;

    -- fallback إذا لم يتم تعريف نطاقات
    IF v_description IS NULL THEN
        IF p_percentage >= 90 THEN SET v_description = 'ممتاز';
        ELSEIF p_percentage >= 80 THEN SET v_description = 'جيد جداً';
        ELSEIF p_percentage >= 65 THEN SET v_description = 'جيد';
        ELSEIF p_percentage >= 50 THEN SET v_description = 'مقبول';
        ELSE SET v_description = 'ضعيف';
        END IF;
    END IF;

    RETURN v_description;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. View: تفاصيل درجات المواد للشهر
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_rpt_monthly_subject_details AS
SELECT
    se.id AS enrollment_id,
    stu.full_name AS student_name,
    gl.name_ar AS grade_level,
    c.name_ar AS classroom_name,

    am.id AS month_id,
    am.name_ar AS month_name,
    ay.name_ar AS academic_year_hijri,
    ay.name_en AS academic_year_gregorian,

    sub.id AS subject_id,
    sub.name_ar AS subject_name,
    sub.sort_order AS order_index,

    COALESCE(mg.attendance_score, 0) AS report_attendance,
    COALESCE(mg.homework_score, 0) AS report_homework,
    COALESCE(mg.activity_score, 0) AS report_activity,
    COALESCE(mg.contribution_score, 0) AS report_contribution,
    COALESCE(mg.custom_components_score, 0) AS report_custom_components,
    COALESCE(mg.exam_score, 0) AS report_exam,

    COALESCE(mg.monthly_total, 0) AS report_total,

    (
        COALESCE(gp.max_exam_score, 0)
        + COALESCE(gp.max_activity_score, 0)
        + COALESCE(gp.max_homework_score, 0)
        + COALESCE(gp.max_attendance_score, 0)
        + COALESCE(gp.max_contribution_score, 0)
        + COALESCE(gpcc_sum.max_custom_score, 0)
    ) AS report_max_score,

    fn_get_grade_description(
        CASE
            WHEN (
                COALESCE(gp.max_exam_score, 0)
                + COALESCE(gp.max_activity_score, 0)
                + COALESCE(gp.max_homework_score, 0)
                + COALESCE(gp.max_attendance_score, 0)
                + COALESCE(gp.max_contribution_score, 0)
                + COALESCE(gpcc_sum.max_custom_score, 0)
            ) > 0
            THEN (
                COALESCE(mg.monthly_total, 0) /
                (
                    COALESCE(gp.max_exam_score, 0)
                    + COALESCE(gp.max_activity_score, 0)
                    + COALESCE(gp.max_homework_score, 0)
                    + COALESCE(gp.max_attendance_score, 0)
                    + COALESCE(gp.max_contribution_score, 0)
                    + COALESCE(gpcc_sum.max_custom_score, 0)
                )
            ) * 100
            ELSE 0
        END
    ) AS report_grade_desc

FROM monthly_grades mg
JOIN student_enrollments se ON mg.enrollment_id = se.id
JOIN students stu ON se.student_id = stu.id
JOIN classrooms c ON se.classroom_id = c.id
JOIN grade_levels gl ON c.grade_level_id = gl.id
JOIN academic_months am ON mg.month_id = am.id
JOIN semesters sem ON am.semester_id = sem.id
JOIN academic_years ay ON sem.academic_year_id = ay.id
JOIN subjects sub ON mg.subject_id = sub.id
LEFT JOIN grading_policies gp ON (
    gp.grade_level_id = gl.id
    AND gp.subject_id = sub.id
    AND gp.academic_year_id = ay.id
    AND gp.exam_type_id = 1 -- MONTHLY
)
LEFT JOIN (
    SELECT
        gpcc.policy_id,
        SUM(gpcc.max_score) AS max_custom_score
    FROM grading_policy_custom_components gpcc
    WHERE gpcc.is_active = TRUE
      AND gpcc.include_in_monthly = TRUE
    GROUP BY gpcc.policy_id
) gpcc_sum ON gpcc_sum.policy_id = gp.id
ORDER BY sub.sort_order;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. View: ملخص الطالب الشهري
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_rpt_monthly_student_summary AS
SELECT
    base.enrollment_id,
    base.month_id,
    base.student_name,
    base.classroom_id,
    COALESCE(base.total_days_recorded, 0) AS total_days_recorded,
    COALESCE(base.present_days, 0) AS present_days,
    COALESCE(base.absent_days, 0) AS absent_days,
    base.student_total_score,
    base.student_max_score,

    CASE
        WHEN base.student_max_score > 0
        THEN (base.student_total_score / base.student_max_score) * 100
        ELSE 0
    END AS student_percentage,

    RANK() OVER (
        PARTITION BY base.classroom_id, base.month_id
        ORDER BY
            CASE
                WHEN base.student_max_score > 0
                THEN (base.student_total_score / base.student_max_score) * 100
                ELSE 0
            END DESC,
            base.student_total_score DESC,
            base.student_name ASC
    ) AS rank_in_class

FROM (
    SELECT
        se.id AS enrollment_id,
        mg.month_id,
        stu.full_name AS student_name,
        se.classroom_id,

        COALESCE(att.total_days, 0) AS total_days_recorded,
        COALESCE(att.present_days, 0) AS present_days,
        COALESCE(att.absent_days, 0) AS absent_days,

        SUM(COALESCE(mg.monthly_total, 0)) AS student_total_score,

        SUM(
            COALESCE(gp.max_exam_score, 0)
            + COALESCE(gp.max_activity_score, 0)
            + COALESCE(gp.max_homework_score, 0)
            + COALESCE(gp.max_attendance_score, 0)
            + COALESCE(gp.max_contribution_score, 0)
            + COALESCE(gpcc_sum.max_custom_score, 0)
        ) AS student_max_score

    FROM monthly_grades mg
    JOIN student_enrollments se ON mg.enrollment_id = se.id
    JOIN students stu ON se.student_id = stu.id
    JOIN classrooms c ON se.classroom_id = c.id
    JOIN grade_levels gl ON c.grade_level_id = gl.id
    JOIN academic_months am ON mg.month_id = am.id
    JOIN semesters sem ON am.semester_id = sem.id

    LEFT JOIN grading_policies gp ON (
        gp.grade_level_id = gl.id
        AND gp.subject_id = mg.subject_id
        AND gp.academic_year_id = sem.academic_year_id
        AND gp.exam_type_id = 1 -- MONTHLY
    )

    LEFT JOIN (
        SELECT
            gpcc.policy_id,
            SUM(gpcc.max_score) AS max_custom_score
        FROM grading_policy_custom_components gpcc
        WHERE gpcc.is_active = TRUE
          AND gpcc.include_in_monthly = TRUE
        GROUP BY gpcc.policy_id
    ) gpcc_sum ON gpcc_sum.policy_id = gp.id

    LEFT JOIN (
        SELECT
            sa.enrollment_id,
            am2.id AS month_id,
            COUNT(sa.id) AS total_days,
            SUM(CASE WHEN sa.status_id = 1 THEN 1 ELSE 0 END) AS present_days,
            SUM(CASE WHEN sa.status_id != 1 THEN 1 ELSE 0 END) AS absent_days
        FROM student_attendance sa
        JOIN academic_months am2
            ON sa.attendance_date BETWEEN am2.start_date AND am2.end_date
        GROUP BY sa.enrollment_id, am2.id
    ) att ON att.enrollment_id = se.id
         AND att.month_id = mg.month_id

    GROUP BY
        se.id,
        mg.month_id,
        stu.full_name,
        se.classroom_id,
        att.total_days,
        att.present_days,
        att.absent_days
) base;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. إرشادات الاستخدام
-- ═══════════════════════════════════════════════════════════════════════════════
/*
-- 1) تفاصيل مواد الطالب في شهر معين:
SELECT
    subject_name,
    report_attendance,
    report_homework,
    report_activity,
    report_contribution,
    report_custom_components,
    report_exam,
    report_total,
    report_grade_desc
FROM v_rpt_monthly_subject_details
WHERE enrollment_id = 1 AND month_id = 1
ORDER BY order_index;

-- 2) ملخص الطالب الشهري:
SELECT
    student_total_score,
    student_max_score,
    student_percentage,
    rank_in_class,
    total_days_recorded,
    present_days,
    absent_days
FROM v_rpt_monthly_student_summary
WHERE enrollment_id = 1 AND month_id = 1;
*/
