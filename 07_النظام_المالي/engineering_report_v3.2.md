# 📋 التقرير الهندسي الشامل — النظام المالي المتقدم v3.2

## إعداد: م. عماد الجماعي · المستلم: م. موسى العواضي

### التاريخ: 2026-03-04 · المشروع: School ERP — النظام المالي (07)

---

## 📌 ملخص تنفيذي

نظام محاسبي احترافي متكامل مبني على **القيد المزدوج**. مصمم لخدمة **عدة مدارس** بمتطلبات متنوعة.

| المكون           | العدد                        |
| ---------------- | ---------------------------- |
| جداول [ADVANCED] | 28                           |
| جداول [LEGACY]   | 7                            |
| Views            | 9 (2 Legacy + 7 Advanced)    |
| Triggers         | 2 (حماية الفترات المغلقة)    |
| صناديق مالية     | 12 (2 رئيسي + 10 فرعي)       |
| تصنيفات مالية    | 27 (15 إيراد + 12 مصروف)     |
| حسابات CoA       | 36 حساب أساسي                |
| أكواد ضريبية     | 5 (OUTPUT/INPUT/EXEMPT/ZERO) |
| مراكز تكلفة      | 5 بذرية                      |
| تسلسلات ترقيم    | 6 أنواع مستندات              |

---

## 📂 الملفات

| الملف                              | السطور    | الوصف                     |
| ---------------------------------- | --------- | ------------------------- |
| `DDL.sql`                          | ~1500     | الهيكلية الموحدة          |
| `README.md`                        | ~140      | التوثيق الشامل            |
| `engineering_report_v3.2.md`       | هذا الملف | تقرير هندسي مفصل          |
| `advanced_finance_architecture.md` | ~250      | تحليل + Sequence Diagrams |
| `advanced_finance_integration.md`  | ~200      | 30+ API Endpoint          |
| `advanced_finance_phases.md`       | ~300      | 4 Sprints خطة تنفيذ       |

---

## 🏦 الصناديق المالية (12 صندوق)

| #   | الرمز              | الصندوق            | النوع | الغرض التشغيلي                                |
| --- | ------------------ | ------------------ | ----- | --------------------------------------------- |
| 1   | `MAIN_FUND`        | الرئيسي العام      | رئيسي | الحركة العامة — يستقبل التحويلات بين الصناديق |
| 2   | `PAYROLL_FUND`     | الرواتب والأجور    | رئيسي | فصل أموال الرواتب — ضمان الصرف الشهري         |
| 3   | `COMMUNITY_FUND`   | المساهمة المجتمعية | فرعي  | الأقساط الشهرية للطلاب                        |
| 4   | `TUITION_FUND`     | الرسوم الدراسية    | فرعي  | رسوم تسجيل وتعليم سنوية                       |
| 5   | `TRANSPORT_FUND`   | النقل المدرسي      | فرعي  | اشتراكات باصات + وقود + صيانة                 |
| 6   | `ACTIVITIES_FUND`  | الأنشطة والفعاليات | فرعي  | رحلات، مسابقات، أيام مفتوحة                   |
| 7   | `MAINTENANCE_FUND` | الصيانة والتشغيل   | فرعي  | إصلاحات، كهرباء، مياه                         |
| 8   | `PROCUREMENT_FUND` | المشتريات واللوازم | فرعي  | قرطاسية، أدوات، معدات                         |
| 9   | `CAFETERIA_FUND`   | المقصف/الكافتيريا  | فرعي  | إيرادات ومصروفات المقصف                       |
| 10  | `DONATIONS_FUND`   | التبرعات والمنح    | فرعي  | فصل محاسبي مطلوب قانونياً                     |
| 11  | `DEVELOPMENT_FUND` | التطوير والتحسين   | فرعي  | مشاريع تطويرية ورأسمالية                      |
| 12  | `EMERGENCY_FUND`   | الطوارئ والاحتياطي | فرعي  | احتياطي — لا يُصرف إلا بموافقة                |

---

## 📋 التصنيفات المالية (27 تصنيف)

### إيرادات (15 تصنيف)

| الرمز                 | التصنيف                   |
| --------------------- | ------------------------- |
| `REV_COMMUNITY`       | المساهمة المجتمعية        |
| `REV_REGISTRATION`    | رسوم التسجيل والقبول      |
| `REV_TUITION`         | الرسوم الدراسية (الأقساط) |
| `REV_TRANSPORT`       | رسوم النقل المدرسي        |
| `REV_UNIFORM`         | رسوم الزي المدرسي         |
| `REV_BOOKS`           | رسوم الكتب والقرطاسية     |
| `REV_ACTIVITIES`      | رسوم الأنشطة والفعاليات   |
| `REV_CAFETERIA`       | إيرادات المقصف/الكافتيريا |
| `REV_EXAMS`           | رسوم الامتحانات           |
| `REV_LATE_FEE`        | غرامات التأخير            |
| `REV_DONATION`        | تبرعات ومنح               |
| `REV_FACILITY_RENTAL` | إيرادات تأجير المرافق     |
| `REV_CERTIFICATES`    | رسوم الشهادات والوثائق    |
| `REV_TRAINING`        | رسوم الدورات التدريبية    |
| `REV_OTHER`           | إيرادات متنوعة أخرى       |

### مصروفات (12 تصنيف)

| الرمز             | التصنيف                  |
| ----------------- | ------------------------ |
| `EXP_SALARY`      | رواتب وأجور ومكافآت      |
| `EXP_MAINTENANCE` | صيانة وإصلاحات           |
| `EXP_FUEL`        | وقود ومواصلات            |
| `EXP_UTILITIES`   | كهرباء ومياه وخدمات      |
| `EXP_RENT`        | إيجارات                  |
| `EXP_SUPPLIES`    | مشتريات وقرطاسية ولوازم  |
| `EXP_EQUIPMENT`   | أثاث ومعدات وأجهزة       |
| `EXP_IT`          | تقنية معلومات وبرمجيات   |
| `EXP_TRAINING`    | تدريب وتطوير مهني        |
| `EXP_PRINTING`    | طباعة ونسخ وتصوير        |
| `EXP_EVENTS`      | ضيافة واحتفالات وفعاليات |
| `EXP_CLEANING`    | نظافة وتعقيم وأمن        |
| `EXP_MISC`        | نثريات ومصروفات متنوعة   |

---

## 🏗️ الجداول الـ 35 — حسب القسم

### القسم 1-4: [LEGACY] (7 جداول)

`lookup_payment_types` · `lookup_exemption_reasons` · `lookup_contribution_amounts` · `financial_categories` (27 بذرة) · `financial_funds` (12 بذرة) · `revenues` · `expenses` · `community_contributions` · `financial_view_logs`

### القسم 5: الفروع والعملات (3 جداول)

`branches` · `currencies` (3 بذور: YER, SAR, USD) · `currency_exchange_rates`

### القسم 6: السنوات المالية + CoA (3 جداول)

`fiscal_years` · `fiscal_periods` (OPEN/CLOSING/CLOSED/REOPENED) · `chart_of_accounts` (36 حساب)

### القسم 7: القيد المزدوج (2 جدول)

`journal_entries` (مع `fiscal_period_id` + `exchange_rate DECIMAL(10,6)`) · `journal_entry_lines`

### القسم 8: الفوترة (4 جداول)

`fee_structures` · `discount_rules` (مع `discount_gl_account_id` + `contra_gl_account_id`) · `student_invoices` · `invoice_line_items` (مع `tax_code_id` + `discount_gl_account_id`) · `invoice_installments`

### القسم 9: الدفع والتسويات (4 جداول)

`payment_gateways` (3 بوابات) · `payment_transactions` · `bank_reconciliation` · `reconciliation_items`

### القسم 10: الضرائب (1 جدول)

`fin_tax_codes` (5 بذور: VAT15, VAT5, VAT0, EXEMPT, VAT_IN15)

### القسم 14-20: الفجوات المسدودة (8 جداول)

`audit_trail` · `budgets` · `budget_lines` · `credit_debit_notes` · `document_sequences` (6 بذور) · `recurring_journal_templates` · `recurring_template_lines` · `cost_centers` (5 بذور)

---

## ⚡ الـ Triggers (2)

| Trigger                             | الوظيفة                                                                |
| ----------------------------------- | ---------------------------------------------------------------------- |
| `trg_je_before_update_check_period` | يمنع ترحيل (POST) قيد في فترة مغلقة/قيد الإقفال + يمنع تعديل قيد مرحّل |
| `trg_je_before_insert_check_period` | يمنع إنشاء قيد بتاريخ في فترة مغلقة + يملأ `fiscal_period_id` تلقائياً |

---

## 📊 الـ Views (9)

| View                                 | النوع    | الوصف                            |
| ------------------------------------ | -------- | -------------------------------- |
| `v_unified_financial_status`         | LEGACY   | أرصدة الصناديق مع CoA            |
| `v_community_contributions_analysis` | LEGACY   | تحليل المساهمات                  |
| `v_general_ledger`                   | ADVANCED | دفتر الأستاذ + الفترة المالية    |
| `v_trial_balance`                    | ADVANCED | ميزان المراجعة                   |
| `v_student_account_statement`        | ADVANCED | كشف حساب الطالب                  |
| `v_vat_return_report`                | ADVANCED | الإقرار الضريبي حسب كود VAT      |
| `v_budget_vs_actual`                 | ADVANCED | الميزانية vs الفعلي + مؤشر الصحة |
| `v_accounts_receivable_aging`        | ADVANCED | أعمار الديون 30/60/90/120+ يوم   |

---

## 🔗 أعمدة [BRIDGE] — ربط Legacy بـ Advanced

| الجدول القديم             | العمود             | يُشير إلى           |
| ------------------------- | ------------------ | ------------------- |
| `financial_categories`    | `coa_account_id`   | `chart_of_accounts` |
| `financial_funds`         | `coa_account_id`   | `chart_of_accounts` |
| `revenues`                | `journal_entry_id` | `journal_entries`   |
| `expenses`                | `journal_entry_id` | `journal_entries`   |
| `community_contributions` | `invoice_id`       | `student_invoices`  |
| `community_contributions` | `journal_entry_id` | `journal_entries`   |

---

## 🔄 سجل الإصدارات

| الإصدار | التاريخ    | التغييرات                                                                                                     |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------- |
| v2.0    | سابق       | النظام الأساسي: صناديق + إيرادات + مصروفات                                                                    |
| v3.0    | 2026-03-02 | القيد المزدوج + CoA + فوترة + دفع + تسويات + فروع + عملات                                                     |
| v3.1    | 2026-03-03 | إقفال فترات + محرك ضرائب + دقة صرف + توجيه خصومات                                                             |
| v3.2    | 2026-03-04 | Audit Trail + ميزانيات + مذكرات ائتمان + ترقيم + قيود متكررة + مراكز تكلفة + أعمار ديون + 12 صندوق + 27 تصنيف |

---

## ✅ قائمة التحقق للمهندس موسى

- [ ] مراجعة الـ 12 صندوق — هل تحتاج المدارس صناديق إضافية؟
- [ ] مراجعة الـ 27 تصنيف — هل النسبة بين الإيرادات (15) والمصروفات (12) كافية؟
- [ ] مراجعة شجرة الحسابات (36 حساب) — هل تناسب الهيكل المحاسبي؟
- [ ] مراجعة أكواد الضرائب (5 أكواد) — هل النسب صحيحة حسب النظام المحلي؟
- [ ] اختبار Triggers الإقفال على بيئة تطوير
- [ ] مراجعة View أعمار الديون — هل فئات 30/60/90/120 مناسبة؟
- [ ] مراجعة مراكز التكلفة الخمسة — هل تحتاج مراكز إضافية؟

---

**إعداد:** م. عماد الجماعي — Software & Enterprise Architect
**شركة إنما سوفت للحلول التقنية (InmaSoft)** | 2026-03-04
