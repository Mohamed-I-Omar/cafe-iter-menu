-- ============================================================
-- Café Iter — إعداد قاعدة بيانات Supabase (شغّله مرة واحدة)
-- افتح Supabase → مشروعك → SQL Editor → New query → الصق ده كله → Run
-- ⚠️ غيّر كلمة السر في السطر المكتوب فيه CHANGE_THIS_PASSWORD
-- ============================================================

-- 1) جدول المنيو (صف واحد يحمل كل المنيو كـ JSON)
create table if not exists public.menu (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz default now()
);

-- 2) تفعيل الحماية + السماح للجميع بالقراءة فقط (العملاء)
alter table public.menu enable row level security;

drop policy if exists menu_public_read on public.menu;
create policy menu_public_read on public.menu
  for select using (true);

-- (مفيش سياسة كتابة => محدش يقدر يعدّل الجدول مباشرة بدون كلمة السر)

-- 3) دالة الحفظ: بتتأكد من كلمة السر قبل ما تحفظ
--    ⚠️⚠️ غيّر 'CHANGE_THIS_PASSWORD' لكلمة سر قوية من اختيارك
create or replace function public.save_menu(pwd text, new_data jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if pwd <> 'CHANGE_THIS_PASSWORD' then
    raise exception 'unauthorized';
  end if;

  insert into public.menu (id, data, updated_at)
  values ('iter', new_data, now())
  on conflict (id) do update
    set data = excluded.data, updated_at = now();

  return true;
end;
$$;

-- 4) السماح لزوار الموقع باستدعاء دالة الحفظ (الحماية جوه الدالة بكلمة السر)
grant execute on function public.save_menu(text, jsonb) to anon;
