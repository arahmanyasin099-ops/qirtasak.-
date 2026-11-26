-- =====================================================================
-- قرطاسك | Qirtasak  —  المرحلة الثانية: قاعدة البيانات والتخزين والأمان
-- الصق هذا الملف كاملاً في Supabase > SQL Editor ثم اضغط Run.
-- آمن للتشغيل أكثر من مرة.
-- =====================================================================

-- ---------- 1) الجداول ----------
create table if not exists public.stages (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  title       text not null,
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.grades (
  id          uuid primary key default gen_random_uuid(),
  stage_id    uuid not null references public.stages(id) on delete cascade,
  title       text not null,
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.subjects (
  id          uuid primary key default gen_random_uuid(),
  grade_id    uuid not null references public.grades(id) on delete cascade,
  title       text not null,
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now()
);

-- الكتاب يرتبط بالمادة فقط؛ والمادة ترتبط بالصف، والصف بالمرحلة.
-- لذلك لا يمكن أن يحدث تناقض بين مرحلة الكتاب وصفه ومادته.
create table if not exists public.books (
  id               uuid primary key default gen_random_uuid(),
  subject_id       uuid not null references public.subjects(id) on delete cascade,
  title            text not null,
  cover_url        text check (cover_url is null or cover_url like 'https://%'),
  pdf_url          text not null check (pdf_url like 'https://%'),
  pages            int,
  file_size_bytes  bigint,
  is_published     boolean not null default false,
  downloads_count  int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists grades_stage_idx    on public.grades(stage_id);
create index if not exists subjects_grade_idx  on public.subjects(grade_id);
create index if not exists books_subject_idx   on public.books(subject_id);
create index if not exists books_created_idx   on public.books(created_at desc);
create index if not exists books_downloads_idx on public.books(downloads_count desc);

-- تحديث updated_at عند تعديل بيانات الكتاب (وليس عند زيادة عدّاد التحميل)
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
  before update on public.books
  for each row
  when (old.downloads_count is not distinct from new.downloads_count)
  execute function public.set_updated_at();

-- ---------- 2) عرض موحّد للتطبيق (يجمع الكتاب والمادة والصف والمرحلة) ----------
create or replace view public.book_details
with (security_invoker = true) as
select
  b.id, b.title, b.cover_url, b.pdf_url, b.pages, b.file_size_bytes,
  b.downloads_count, b.created_at,
  b.subject_id, s.title as subject_title,
  g.id as grade_id, g.title as grade_title,
  st.id as stage_id, st.title as stage_title
from public.books b
join public.subjects s on s.id = b.subject_id
join public.grades   g on g.id = s.grade_id
join public.stages  st on st.id = g.stage_id
where b.is_published;

-- ---------- 3) سياسات الأمان (RLS) ----------
-- الطلاب (anon) يقرؤون فقط. لا إضافة ولا تعديل ولا حذف من التطبيق.
alter table public.stages   enable row level security;
alter table public.grades   enable row level security;
alter table public.subjects enable row level security;
alter table public.books    enable row level security;

drop policy if exists "public read stages"   on public.stages;
drop policy if exists "public read grades"   on public.grades;
drop policy if exists "public read subjects" on public.subjects;
drop policy if exists "public read published books" on public.books;

create policy "public read stages"   on public.stages   for select to anon, authenticated using (true);
create policy "public read grades"   on public.grades   for select to anon, authenticated using (true);
create policy "public read subjects" on public.subjects for select to anon, authenticated using (true);
create policy "public read published books" on public.books
  for select to anon, authenticated using (is_published);

revoke all on public.stages, public.grades, public.subjects, public.books
  from anon, authenticated;
grant select on public.stages, public.grades, public.subjects, public.books
  to anon, authenticated;
grant select on public.book_details to anon, authenticated;

-- ---------- 4) عدّاد التحميل (الدالة الوحيدة التي تعدّل جدول الكتب من التطبيق) ----------
create or replace function public.increment_downloads(p_book_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.books
     set downloads_count = downloads_count + 1
   where id = p_book_id and is_published;
$$;

revoke all on function public.increment_downloads(uuid) from public;
grant execute on function public.increment_downloads(uuid) to anon, authenticated;

-- ---------- 5) التخزين السحابي ----------
-- bucket عام للقراءة والتحميل، ولا توجد أي سياسة كتابة للطلاب.
-- الرفع يتم فقط من لوحة Supabase (حسابك أنت) أو من لوحة الإدارة لاحقاً.
-- ملاحظة: الخطة المجانية تمنع رفع ملف أكبر من 50 ميغابايت.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('books',  'books',  true, 52428800, array['application/pdf']),
  ('covers', 'covers', true, 5242880,  array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ---------- 6) هيكل المراحل والصفوف والمواد (بدون أي كتب) ----------
-- هذه قوائم مبدئية؛ عدّلها من Table Editor لتطابق المنهج السوداني.
insert into public.stages (slug, title, sort_order) values
  ('primary',   'المرحلة الابتدائية', 1),
  ('middle',    'المرحلة المتوسطة',   2),
  ('secondary', 'المرحلة الثانوية',   3)
on conflict (slug) do nothing;

do $$
declare
  st record;
  g_id uuid;
  i int; j int; n int;
  suffix text;
  subj text[];
  ord text[] := array['الأول','الثاني','الثالث','الرابع','الخامس','السادس'];
begin
  for st in select id, slug from public.stages loop
    if exists (select 1 from public.grades where stage_id = st.id) then
      continue;
    end if;

    if st.slug = 'primary' then
      n := 6; suffix := '';
      subj := array['اللغة العربية','الرياضيات','العلوم','التربية الإسلامية','اللغة الإنجليزية','الدراسات الاجتماعية'];
    elsif st.slug = 'middle' then
      n := 3; suffix := ' المتوسط';
      subj := array['اللغة العربية','الرياضيات','العلوم','التربية الإسلامية','اللغة الإنجليزية','التاريخ','الجغرافيا'];
    elsif st.slug = 'secondary' then
      n := 3; suffix := ' الثانوي';
      subj := array['اللغة العربية','اللغة الإنجليزية','التربية الإسلامية','الرياضيات','الفيزياء','الكيمياء','الأحياء','التاريخ','الجغرافيا'];
    else
      continue;
    end if;

    for i in 1..n loop
      insert into public.grades (stage_id, title, sort_order)
      values (st.id, 'الصف ' || ord[i] || suffix, i)
      returning id into g_id;

      for j in 1..array_length(subj, 1) loop
        insert into public.subjects (grade_id, title, sort_order)
        values (g_id, subj[j], j);
      end loop;
    end loop;
  end loop;
end $$;
