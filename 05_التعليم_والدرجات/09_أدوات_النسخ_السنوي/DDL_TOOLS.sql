-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║           نظام الدرجات والتقويم الذكي (SGAS) - v4.0                        ║
-- ║           ملف 9: أدوات النسخ والتهيئة السنوية (Tools)                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- التاريخ: 2026-02-19
-- الإصدار: 4.0 (§3.1 — إعادة استخدام الإعدادات بين الأعوام الدراسية)
-- الوصف: Stored Procedures لنسخ السياسات والفترات بين الأعوام

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. نسخ سياسات الدرجات من عام سابق إلى عام جديد
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_copy_policies(
    IN p_source_year_id INT,
    IN p_target_year_id INT
)
BEGIN
    DECLARE v_source_exists INT DEFAULT 0;
    DECLARE v_target_exists INT DEFAULT 0;
    DECLARE v_copied_count INT DEFAULT 0;

    -- التحقق من وجود العامين
    SELECT COUNT(*) INTO v_source_exists FROM academic_years WHERE id = p_source_year_id;
    SELECT COUNT(*) INTO v_target_exists FROM academic_years WHERE id = p_target_year_id;

    IF v_source_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'العام الدراسي المصدر غير موجود';
    END IF;

    IF v_target_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'العام الدراسي الهدف غير موجود';
    END IF;

    IF p_source_year_id = p_target_year_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن النسخ من العام نفسه إلى نفسه';
    END IF;

    -- نسخ السياسات الأساسية
    INSERT INTO grading_policies (
        academic_year_id, grade_level_id, subject_id, exam_type_id,
        max_exam_score, max_homework_score, max_attendance_score,
        max_activity_score, max_contribution_score, passing_score,
        is_default, created_by_user_id
    )
    SELECT
        p_target_year_id, grade_level_id, subject_id, exam_type_id,
        max_exam_score, max_homework_score, max_attendance_score,
        max_activity_score, max_contribution_score, passing_score,
        is_default, created_by_user_id
    FROM grading_policies
    WHERE academic_year_id = p_source_year_id
    ON DUPLICATE KEY UPDATE
        max_exam_score = VALUES(max_exam_score),
        max_homework_score = VALUES(max_homework_score),
        max_attendance_score = VALUES(max_attendance_score),
        max_activity_score = VALUES(max_activity_score),
        max_contribution_score = VALUES(max_contribution_score),
        passing_score = VALUES(passing_score),
        updated_at = CURRENT_TIMESTAMP;

    SET v_copied_count = ROW_COUNT();

    -- نسخ المكونات المخصصة للسياسات الجديدة
    INSERT IGNORE INTO grading_policy_custom_components (
        policy_id, component_code, component_name_ar, max_score,
        calculation_mode, include_in_monthly, include_in_semester, sort_order, is_active
    )
    SELECT
        gp_new.id, gpcc.component_code, gpcc.component_name_ar, gpcc.max_score,
        gpcc.calculation_mode, gpcc.include_in_monthly, gpcc.include_in_semester,
        gpcc.sort_order, gpcc.is_active
    FROM grading_policy_custom_components gpcc
    JOIN grading_policies gp_old ON gpcc.policy_id = gp_old.id
    JOIN grading_policies gp_new ON gp_new.academic_year_id = p_target_year_id
        AND gp_new.grade_level_id = gp_old.grade_level_id
        AND gp_new.subject_id = gp_old.subject_id
        AND gp_new.exam_type_id = gp_old.exam_type_id
    WHERE gp_old.academic_year_id = p_source_year_id;

    SELECT CONCAT('✅ تم نسخ ', v_copied_count, ' سياسة + مكوناتها المخصصة') AS result;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. نسخ الفترات الامتحانية من عام سابق إلى عام جديد
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_copy_exam_periods(
    IN p_source_year_id INT,
    IN p_target_year_id INT
)
BEGIN
    DECLARE v_copied_count INT DEFAULT 0;

    -- التحقق
    IF p_source_year_id = p_target_year_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن النسخ من العام نفسه إلى نفسه';
    END IF;

    -- نسخ الفترات (بدون التواريخ — تُعبأ من نظام الجدولة)
    INSERT INTO exam_periods (
        academic_year_id, semester_id, name_ar, exam_type_id,
        is_active, status_id, created_by
    )
    SELECT
        p_target_year_id,
        -- ربط بالفصل المقابل في العام الجديد
        (SELECT s2.id FROM semesters s2
         WHERE s2.academic_year_id = p_target_year_id
           AND s2.semester_number = s1.semester_number
         LIMIT 1),
        ep.name_ar,
        ep.exam_type_id,
        TRUE, -- is_active
        1,    -- DRAFT
        ep.created_by
    FROM exam_periods ep
    JOIN semesters s1 ON ep.semester_id = s1.id
    WHERE ep.academic_year_id = p_source_year_id
      AND ep.is_active = TRUE;

    SET v_copied_count = ROW_COUNT();

    SELECT CONCAT('✅ تم نسخ ', v_copied_count, ' فترة امتحانية (بدون تواريخ — تُضاف من الجدولة)') AS result;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. نسخ قواعد النقل من عام سابق إلى عام جديد
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_copy_outcome_rules(
    IN p_source_year_id INT,
    IN p_target_year_id INT
)
BEGIN
    DECLARE v_copied_count INT DEFAULT 0;

    IF p_source_year_id = p_target_year_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'لا يمكن النسخ من العام نفسه إلى نفسه';
    END IF;

    INSERT INTO grading_outcome_rules (
        academic_year_id, grade_level_id,
        promoted_max_failed_subjects, conditional_max_failed_subjects,
        conditional_decision_id, retained_decision_id,
        tie_break_strategy, is_active, created_by_user_id
    )
    SELECT
        p_target_year_id, grade_level_id,
        promoted_max_failed_subjects, conditional_max_failed_subjects,
        conditional_decision_id, retained_decision_id,
        tie_break_strategy, TRUE, created_by_user_id
    FROM grading_outcome_rules
    WHERE academic_year_id = p_source_year_id
      AND is_active = TRUE
    ON DUPLICATE KEY UPDATE
        promoted_max_failed_subjects = VALUES(promoted_max_failed_subjects),
        conditional_max_failed_subjects = VALUES(conditional_max_failed_subjects),
        conditional_decision_id = VALUES(conditional_decision_id),
        retained_decision_id = VALUES(retained_decision_id),
        tie_break_strategy = VALUES(tie_break_strategy),
        updated_at = CURRENT_TIMESTAMP;

    SET v_copied_count = ROW_COUNT();

    SELECT CONCAT('✅ تم نسخ ', v_copied_count, ' قاعدة نقل') AS result;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. Procedure شاملة: نسخ كل إعدادات العام
-- ═══════════════════════════════════════════════════════════════════════════════

DELIMITER //

CREATE PROCEDURE sp_copy_all_year_settings(
    IN p_source_year_id INT,
    IN p_target_year_id INT
)
BEGIN
    CALL sp_copy_policies(p_source_year_id, p_target_year_id);
    CALL sp_copy_exam_periods(p_source_year_id, p_target_year_id);
    CALL sp_copy_outcome_rules(p_source_year_id, p_target_year_id);

    SELECT '✅ تم نسخ جميع إعدادات العام (سياسات + فترات + قواعد نقل)' AS result;
END//

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════════════
SELECT '✅ DDL_TOOLS v4.0: أدوات النسخ السنوي (3 SP + 1 SP شاملة)' AS message;
