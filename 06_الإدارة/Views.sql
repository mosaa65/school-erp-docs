-- 📊 رؤى الحوكمة والرقابة (Governance & Incident Views)
-- 📂 System 06: Administration
-- 🏗️ Architectural Lead: Antigravity AI

-- التاريخ: 2026-01-16

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. كشوفات الزوار (Visitor Reporting Views)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_gov_visitor_master AS
SELECT 
    v.id,
    v.visitor_name,
    g.name_ar AS gender,
    vs.name_ar AS visitor_source,
    v.position_title,
    v.visit_purpose,
    v.visit_reason,
    ay.name_ar AS academic_year,
    s.name_ar AS semester,
    hm.name_ar AS hijri_month,
    v.week_id AS week_number,
    d.name_ar AS day_name,
    v.entry_time,
    v.exit_time,
    e.full_name AS hosted_by,
    v.is_documented_in_record
FROM visitor_logs v
JOIN lookup_genders g ON v.gender_id = g.id
JOIN lookup_visitor_sources vs ON v.visitor_source_id = vs.id
JOIN academic_years ay ON v.academic_year_id = ay.id
JOIN semesters s ON v.semester_id = s.id
JOIN lookup_hijri_months hm ON v.hijri_month_id = hm.id
JOIN lookup_days d ON v.day_id = d.id
JOIN employees e ON v.hosted_by_employee_id = e.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. كشوفات المشكلات (Incident Reporting Views)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_gov_incident_master AS
SELECT 
    i.id,
    tt.name_ar AS target_entity_type,
    i.entity_name,
    i.incident_sequence,
    g.name_ar AS gender,
    i.incident_date,
    ay.name_ar AS academic_year,
    sem.name_ar AS semester,
    hm.name_ar AS hijri_month,
    i.week_id AS week_number,
    d.name_ar AS day_name,
    i.incident_title,
    i.incident_description,
    i.adversaries_names,
    i.witnesses_names,
    i.actions_taken,
    i.has_official_minutes,
    i.is_resolved,
    u.username AS reported_by,
    i.created_at
FROM gov_incidents i
JOIN lookup_incident_target_types tt ON i.target_type_id = tt.id
JOIN lookup_genders g ON i.gender_id = g.id
JOIN academic_years ay ON i.academic_year_id = ay.id
JOIN semesters sem ON i.semester_id = sem.id
JOIN lookup_hijri_months hm ON i.hijri_month_id = hm.id
JOIN lookup_days d ON i.day_id = d.id
JOIN users u ON i.created_by_user_id = u.id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. تقارير مخصصة (Specialized Output Views)
-- ═══════════════════════════════════════════════════════════════════════════════

-- تقرير مشكلات الطلاب مع بيانات الفصول (Student Incident Detail)
CREATE OR REPLACE VIEW v_gov_student_incidents AS
SELECT 
    vm.*,
    c.name_ar AS classroom_name,
    gl.name_ar AS grade_level
FROM v_gov_incident_master vm
LEFT JOIN students s ON vm.entity_name = s.full_name -- ربط تقريبي بالاسم أو entity_id
LEFT JOIN student_enrollments se ON s.id = se.student_id AND se.is_active = TRUE
LEFT JOIN classrooms c ON se.classroom_id = c.id
LEFT JOIN grade_levels gl ON c.grade_level_id = gl.id
WHERE vm.target_entity_type = 'طالب';

-- تقرير مشكلات الموظفين (Employee Incident Detail)
CREATE OR REPLACE VIEW v_gov_employee_incidents AS
SELECT 
    vm.*,
    e.job_title,
    e.phone_primary
FROM v_gov_incident_master vm
LEFT JOIN employees e ON vm.entity_name = e.full_name
WHERE vm.target_entity_type = 'موظف';
