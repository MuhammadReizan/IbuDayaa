-- IbuDaya — initial schema for the hosted (Supabase) build.
--
-- Mirrors lib/core/db/tables.dart column-for-column so the Supabase
-- repositories map rows exactly like the local ones do.
--
-- Security model
--   * Every table has RLS enabled. Clients read through the policies below.
--   * Anything that changes money, capacity, quota or a loan's status goes
--     through a SECURITY DEFINER function that re-checks the rules, the same
--     checks the local repositories run (lib/core/repositories/local). A
--     modified client cannot approve its own loan or overbook the hub.
--   * Loan submission needs the credit score recomputed server-side; that
--     runs in the `submit-loan` Edge Function (see docs/SUPABASE.md), which
--     calls `private_insert_loan` with the service role.
--
-- STATUS: written to match the local implementation; not yet run against a
-- live project. Apply to a fresh project and run the checks in
-- docs/SUPABASE.md before real members use it.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.cooperatives (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  city text not null default '',
  invite_code text not null unique check (invite_code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  created_by uuid not null,
  loan_flat_monthly_rate_pct numeric(5,2) not null default 2.0 check (loan_flat_monthly_rate_pct between 0 and 5),
  loan_max_amount_idr bigint not null default 5000000 check (loan_max_amount_idr >= 500000),
  loan_min_score int not null default 60 check (loan_min_score between 0 and 100),
  loan_tenors int[] not null default '{3,6,12}',
  member_monthly_quota_kwh numeric not null default 30 check (member_monthly_quota_kwh >= 0),
  solar_cost_per_kwp_idr bigint not null default 15000000 check (solar_cost_per_kwp_idr > 0),
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text not null unique check (phone ~ '^\+628[0-9]{8,12}$'),
  full_name text not null check (length(trim(full_name)) > 0),
  business_name text not null default '',
  city text not null default '',
  role text not null check (role in ('member', 'admin')),
  cooperative_id uuid not null references public.cooperatives (id),
  tariff_idr_per_kwh numeric not null default 1444.70 check (tariff_idr_per_kwh > 0),
  created_at timestamptz not null default now()
);
create index on public.profiles (cooperative_id);

create table public.energy_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('postpaid', 'token')),
  period_month date not null check (period_month = date_trunc('month', period_month)),
  kwh numeric not null check (kwh > 0 and kwh < 20000),
  total_idr bigint not null check (total_idr > 0),
  customer_id text,
  photo_path text,
  source text not null check (source in ('scan', 'manual')),
  created_at timestamptz not null default now()
);
-- One bill per month; tokens may repeat.
create unique index energy_one_bill_per_month
  on public.energy_records (user_id, period_month) where kind = 'postpaid';

create table public.appliances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  kind text not null default 'other',
  watts numeric not null check (watts > 0 and watts <= 20000),
  hours_per_day numeric not null check (hours_per_day > 0 and hours_per_day <= 24),
  days_per_week int not null check (days_per_week between 1 and 7),
  created_at timestamptz not null default now()
);

create table public.roof_assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  photo_path text,
  length_m numeric not null check (length_m > 0),
  width_m numeric not null check (width_m > 0),
  orientation text not null,
  shading text not null,
  usable_area_m2 numeric not null,
  est_kwp numeric not null,
  est_monthly_kwh numeric not null,
  est_monthly_saving_idr bigint not null,
  est_payback_years numeric,
  band text not null,
  created_at timestamptz not null default now()
);

create table public.solar_hubs (
  id uuid primary key default gen_random_uuid(),
  cooperative_id uuid not null references public.cooperatives (id) on delete cascade,
  name text not null,
  location text not null default '',
  daily_capacity_kwh numeric not null default 0 check (daily_capacity_kwh >= 0),
  created_at timestamptz not null default now()
);

create table public.hub_slots (
  id uuid primary key default gen_random_uuid(),
  hub_id uuid not null references public.solar_hubs (id) on delete cascade,
  start_hour int not null check (start_hour between 5 and 18),
  end_hour int not null check (end_hour between 6 and 19 and end_hour > start_hour),
  sort int not null default 0
);

create table public.hub_bookings (
  id uuid primary key default gen_random_uuid(),
  hub_id uuid not null references public.solar_hubs (id) on delete cascade,
  slot_id uuid not null references public.hub_slots (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  appliance_name text not null,
  booking_date date not null,
  est_kwh numeric not null check (est_kwh > 0),
  status text not null default 'booked' check (status in ('booked', 'completed', 'cancelled')),
  created_at timestamptz not null default now()
);
create index on public.hub_bookings (hub_id, booking_date);

create table public.arisan_groups (
  id uuid primary key default gen_random_uuid(),
  cooperative_id uuid not null references public.cooperatives (id) on delete cascade,
  name text not null,
  contribution_idr bigint not null check (contribution_idr >= 1000),
  start_month date not null check (start_month = date_trunc('month', start_month)),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.arisan_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.arisan_groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  turn_order int not null check (turn_order >= 1),
  joined_at timestamptz not null default now(),
  unique (group_id, user_id),
  unique (group_id, turn_order)
);

create table public.arisan_payments (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.arisan_groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('contribution', 'payout')),
  amount_idr bigint not null check (amount_idr > 0),
  period_month date not null,
  status text not null check (status in ('pending', 'confirmed', 'rejected')),
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  note text,
  created_at timestamptz not null default now()
);
create unique index one_live_contribution_per_month
  on public.arisan_payments (group_id, user_id, period_month)
  where type = 'contribution' and status <> 'rejected';
create unique index one_payout_per_month
  on public.arisan_payments (group_id, period_month) where type = 'payout';

create table public.quota_offers (
  id uuid primary key default gen_random_uuid(),
  cooperative_id uuid not null references public.cooperatives (id) on delete cascade,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('share', 'need')),
  kwh numeric not null check (kwh > 0 and kwh <= 1000),
  slot_note text not null default '',
  note text,
  status text not null default 'open' check (status in ('open', 'pending', 'completed', 'cancelled')),
  counterparty_id uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.loan_applications (
  id uuid primary key default gen_random_uuid(),
  cooperative_id uuid not null references public.cooperatives (id),
  user_id uuid not null references public.profiles (id),
  amount_idr bigint not null check (amount_idr >= 500000),
  purpose text not null check (purpose in ('raw_material', 'equipment', 'renovation', 'other')),
  tenor_months int not null check (tenor_months > 0),
  flat_monthly_rate_pct numeric(5,2) not null,
  monthly_installment_idr bigint not null,
  total_repayment_idr bigint not null,
  note text,
  score_snapshot int not null,
  score_band text not null,
  score_factors jsonb not null default '[]',
  status text not null default 'submitted'
    check (status in ('submitted', 'in_review', 'approved', 'rejected', 'disbursed', 'repaid', 'cancelled')),
  decision_note text,
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  disbursed_at timestamptz,
  created_at timestamptz not null default now()
);
-- One open application per member.
create unique index one_active_loan
  on public.loan_applications (user_id)
  where status in ('submitted', 'in_review', 'approved', 'disbursed');

create table public.loan_installments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loan_applications (id) on delete cascade,
  seq int not null,
  due_date date not null,
  amount_idr bigint not null,
  paid_at timestamptz,
  confirmed_by uuid references public.profiles (id),
  unique (loan_id, seq)
);

create table public.loan_events (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loan_applications (id) on delete cascade,
  actor_id uuid references public.profiles (id),
  type text not null,
  note text,
  created_at timestamptz not null default now()
);

create table public.message_threads (
  id uuid primary key default gen_random_uuid(),
  cooperative_id uuid not null references public.cooperatives (id) on delete cascade,
  kind text not null check (kind in ('support', 'announcement', 'group', 'direct')),
  title text not null,
  ref_id uuid,
  created_at timestamptz not null default now()
);

create table public.thread_participants (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz,
  unique (thread_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  sender_id uuid references public.profiles (id),
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index on public.messages (thread_id, created_at);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  route text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.notifications (user_id, created_at desc);

create table public.score_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  month date not null,
  score int not null,
  factor_points jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique (user_id, month)
);

-- ---------------------------------------------------------------------------
-- Helpers (SECURITY DEFINER so policies can call them without recursion)
-- ---------------------------------------------------------------------------

create function public.my_coop() returns uuid
language sql stable security definer set search_path = public as $$
  select cooperative_id from profiles where id = auth.uid()
$$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

create function public.can_see_user(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select uid = auth.uid()
      or (public.is_admin() and exists (
            select 1 from profiles where id = uid and cooperative_id = public.my_coop()))
$$;

create function public.is_participant(t uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from thread_participants where thread_id = t and user_id = auth.uid())
$$;

create function private_require_admin() returns profiles
language plpgsql stable security definer set search_path = public as $$
declare p profiles;
begin
  select * into p from profiles where id = auth.uid();
  if p.id is null or p.role <> 'admin' then
    raise exception 'Hanya admin koperasi yang bisa melakukan ini.' using errcode = '42501';
  end if;
  return p;
end $$;

create function private_require_member() returns profiles
language plpgsql stable security definer set search_path = public as $$
declare p profiles;
begin
  select * into p from profiles where id = auth.uid();
  if p.id is null or p.role <> 'member' then
    raise exception 'Fitur ini khusus untuk anggota koperasi.' using errcode = '42501';
  end if;
  return p;
end $$;

create function private_notify(uid uuid, t text, ttl text, b text, r text default null)
returns void language sql security definer set search_path = public as $$
  insert into notifications (user_id, type, title, body, route) values (uid, t, ttl, b, r)
$$;

create function private_new_invite_code() returns text
language plpgsql volatile security definer set search_path = public as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text;
begin
  loop
    code := '';
    for i in 1..6 loop
      code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from cooperatives where invite_code = code);
  end loop;
  return code;
end $$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.cooperatives enable row level security;
alter table public.profiles enable row level security;
alter table public.energy_records enable row level security;
alter table public.appliances enable row level security;
alter table public.roof_assessments enable row level security;
alter table public.solar_hubs enable row level security;
alter table public.hub_slots enable row level security;
alter table public.hub_bookings enable row level security;
alter table public.arisan_groups enable row level security;
alter table public.arisan_members enable row level security;
alter table public.arisan_payments enable row level security;
alter table public.quota_offers enable row level security;
alter table public.loan_applications enable row level security;
alter table public.loan_installments enable row level security;
alter table public.loan_events enable row level security;
alter table public.message_threads enable row level security;
alter table public.thread_participants enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.score_snapshots enable row level security;

-- Cooperative & people
create policy coop_read on public.cooperatives for select using (id = public.my_coop());
create policy coop_admin_update on public.cooperatives for update
  using (id = public.my_coop() and public.is_admin())
  with check (id = public.my_coop());
revoke update (invite_code, created_by) on public.cooperatives from authenticated;

create policy profiles_read on public.profiles for select using (cooperative_id = public.my_coop());
create policy profiles_self_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());
revoke update (role, cooperative_id, phone) on public.profiles from authenticated;

-- A member's own records; admins of her cooperative may read them.
create policy energy_read on public.energy_records for select using (public.can_see_user(user_id));
create policy energy_write on public.energy_records for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy appliances_read on public.appliances for select using (public.can_see_user(user_id));
create policy appliances_write on public.appliances for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy roof_read on public.roof_assessments for select using (public.can_see_user(user_id));
create policy roof_insert on public.roof_assessments for insert with check (user_id = auth.uid());

-- Hub
create policy hubs_read on public.solar_hubs for select using (cooperative_id = public.my_coop());
create policy hubs_admin on public.solar_hubs for update
  using (cooperative_id = public.my_coop() and public.is_admin());
create policy slots_read on public.hub_slots for select
  using (hub_id in (select id from solar_hubs where cooperative_id = public.my_coop()));
create policy slots_admin on public.hub_slots for all
  using (public.is_admin() and hub_id in (select id from solar_hubs where cooperative_id = public.my_coop()))
  with check (public.is_admin() and hub_id in (select id from solar_hubs where cooperative_id = public.my_coop()));
-- Everyone in the cooperative sees bookings (capacity depends on them);
-- writes only through book_slot / set_booking_status.
create policy bookings_read on public.hub_bookings for select
  using (hub_id in (select id from solar_hubs where cooperative_id = public.my_coop()));

-- Arisan & quota: reads only; writes through functions.
create policy groups_read on public.arisan_groups for select using (cooperative_id = public.my_coop());
create policy group_members_read on public.arisan_members for select
  using (group_id in (select id from arisan_groups where cooperative_id = public.my_coop()));
create policy payments_read on public.arisan_payments for select
  using (
    (public.is_admin() and group_id in (select id from arisan_groups where cooperative_id = public.my_coop()))
    or group_id in (select group_id from arisan_members where user_id = auth.uid())
  );
create policy offers_read on public.quota_offers for select using (cooperative_id = public.my_coop());

-- Loans
create policy loans_read on public.loan_applications for select
  using (user_id = auth.uid() or (public.is_admin() and cooperative_id = public.my_coop()));
create policy installments_read on public.loan_installments for select
  using (loan_id in (select id from loan_applications));
create policy loan_events_read on public.loan_events for select
  using (loan_id in (select id from loan_applications));

-- Messaging
create policy threads_read on public.message_threads for select using (public.is_participant(id));
create policy participants_read on public.thread_participants for select using (public.is_participant(thread_id));
create policy participants_mark_read on public.thread_participants for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy messages_read on public.messages for select using (public.is_participant(thread_id));
create policy messages_send on public.messages for insert
  with check (
    sender_id = auth.uid()
    and public.is_participant(thread_id)
    and (public.is_admin() or (select kind from message_threads where id = thread_id) <> 'announcement')
  );

create policy notifications_own on public.notifications for select using (user_id = auth.uid());
create policy notifications_mark on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy scores_read on public.score_snapshots for select using (public.can_see_user(user_id));

-- ---------------------------------------------------------------------------
-- Accounts
-- ---------------------------------------------------------------------------

-- Called right after supabase.auth.signUp by the first admin.
create function public.register_admin(p_phone text, p_full_name text, p_city text, p_coop_name text)
returns profiles language plpgsql security definer set search_path = public as $$
declare
  c cooperatives;
  p profiles;
  h uuid;
  t uuid;
begin
  if auth.uid() is null then raise exception 'Silakan masuk terlebih dahulu.'; end if;
  if exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'Akun ini sudah terdaftar.';
  end if;
  insert into cooperatives (name, city, invite_code, created_by)
    values (trim(p_coop_name), trim(p_city), private_new_invite_code(), auth.uid())
    returning * into c;
  insert into profiles (id, phone, full_name, city, role, cooperative_id)
    values (auth.uid(), p_phone, trim(p_full_name), trim(p_city), 'admin', c.id)
    returning * into p;
  insert into solar_hubs (cooperative_id, name, location)
    values (c.id, 'Solar Hub ' || c.name, c.city) returning id into h;
  insert into hub_slots (hub_id, start_hour, end_hour, sort)
    values (h, 8, 10, 0), (h, 10, 12, 1), (h, 13, 15, 2), (h, 15, 17, 3);
  insert into message_threads (cooperative_id, kind, title)
    values (c.id, 'announcement', 'Pengumuman ' || c.name) returning id into t;
  insert into thread_participants (thread_id, user_id) values (t, auth.uid());
  return p;
end $$;

create function public.join_cooperative(
  p_invite_code text, p_phone text, p_full_name text, p_business_name text, p_city text
) returns profiles language plpgsql security definer set search_path = public as $$
declare
  c cooperatives;
  p profiles;
  s uuid;
begin
  if auth.uid() is null then raise exception 'Silakan masuk terlebih dahulu.'; end if;
  select * into c from cooperatives where invite_code = upper(trim(p_invite_code));
  if c.id is null then
    raise exception 'Kode koperasi tidak ditemukan. Tanyakan lagi kodenya ke admin koperasi Anda.';
  end if;
  insert into profiles (id, phone, full_name, business_name, city, role, cooperative_id)
    values (auth.uid(), p_phone, trim(p_full_name), trim(p_business_name), trim(p_city), 'member', c.id)
    returning * into p;

  insert into thread_participants (thread_id, user_id)
    select id, auth.uid() from message_threads where cooperative_id = c.id and kind = 'announcement';

  insert into message_threads (cooperative_id, kind, title, ref_id)
    values (c.id, 'support', 'Admin ' || c.name, auth.uid()) returning id into s;
  insert into thread_participants (thread_id, user_id)
    select s, id from profiles where cooperative_id = c.id and (role = 'admin' or id = auth.uid());
  insert into messages (thread_id, body)
    values (s, 'Selamat bergabung di ' || c.name || '. Tanyakan apa saja ke admin di sini.');

  perform private_notify(a.id, 'member', 'Anggota baru bergabung',
    p.full_name || ' (' || p.business_name || ') masuk ke koperasi.', '/a/members/' || p.id)
  from profiles a where a.cooperative_id = c.id and a.role = 'admin';
  return p;
end $$;

-- Lets the join screen show the cooperative's name before signing up.
create function public.find_cooperative(p_invite_code text)
returns table (id uuid, name text, city text)
language sql stable security definer set search_path = public as $$
  select id, name, city from cooperatives where invite_code = upper(trim(p_invite_code))
$$;
grant execute on function public.find_cooperative(text) to anon;

create function public.regenerate_invite_code() returns text
language plpgsql security definer set search_path = public as $$
declare a profiles := private_require_admin(); code text := private_new_invite_code();
begin
  update cooperatives set invite_code = code where id = a.cooperative_id;
  return code;
end $$;

-- ---------------------------------------------------------------------------
-- Solar hub
-- ---------------------------------------------------------------------------

-- Share of the day's sun between two hours (sine arc 06–18), same as
-- lib/core/logic/hub_capacity.dart solarWeight().
create function public.solar_weight(s int, e int) returns numeric
language sql immutable as $$
  select coalesce(sum(sin(pi() * (h + 0.125 - 6) / 12) * 0.25), 0)
  from generate_series(s::numeric, (e - 0.25)::numeric, 0.25) h
  where h + 0.125 > 6 and h + 0.125 < 18
$$;

create function public.member_quota_available(uid uuid, month date) returns numeric
language sql stable security definer set search_path = public as $$
  with c as (
    select co.member_monthly_quota_kwh q
    from profiles p join cooperatives co on co.id = p.cooperative_id where p.id = uid
  ),
  booked as (
    select coalesce(sum(est_kwh), 0) v from hub_bookings
    where user_id = uid and status <> 'cancelled'
      and date_trunc('month', booking_date) = date_trunc('month', month)
  ),
  done as (
    select * from quota_offers
    where status = 'completed' and date_trunc('month', updated_at) = date_trunc('month', month)
  )
  select (select q from c) - (select v from booked)
    - coalesce((select sum(kwh) from done where (kind = 'share' and owner_id = uid) or (kind = 'need' and counterparty_id = uid)), 0)
    + coalesce((select sum(kwh) from done where (kind = 'share' and counterparty_id = uid) or (kind = 'need' and owner_id = uid)), 0)
$$;

create function public.book_slot(p_slot uuid, p_date date, p_appliance text, p_est_kwh numeric)
returns hub_bookings language plpgsql security definer set search_path = public as $$
declare
  me profiles := private_require_member();
  sl hub_slots;
  hub solar_hubs;
  cap numeric;
  used numeric;
  b hub_bookings;
  today date := (now() at time zone 'Asia/Jakarta')::date;
begin
  select * into sl from hub_slots where id = p_slot;
  select * into hub from solar_hubs where id = sl.hub_id;
  if hub.id is null or hub.cooperative_id <> me.cooperative_id then
    raise exception 'Slot ini bukan milik koperasi Anda.';
  end if;
  if hub.daily_capacity_kwh <= 0 then
    raise exception 'Kapasitas Solar Hub belum diatur admin. Booking belum bisa dibuka.';
  end if;
  if p_est_kwh <= 0 then raise exception 'Pilih alat yang akan dipakai.'; end if;
  if p_date < today or p_date > today + 14 then
    raise exception 'Booking hanya bisa untuk hari ini sampai 14 hari ke depan.';
  end if;
  if p_date = today and extract(hour from now() at time zone 'Asia/Jakarta') >= sl.end_hour then
    raise exception 'Slot ini sudah lewat untuk hari ini.';
  end if;

  -- Serialise bookings on this slot/day so two members cannot both take the
  -- last kWh.
  perform pg_advisory_xact_lock(hashtext(p_slot::text || p_date::text));

  select hub.daily_capacity_kwh * public.solar_weight(sl.start_hour, sl.end_hour)
         / nullif(sum(public.solar_weight(start_hour, end_hour)), 0)
    into cap from hub_slots where hub_id = hub.id;
  select coalesce(sum(est_kwh), 0) into used from hub_bookings
    where slot_id = p_slot and booking_date = p_date and status <> 'cancelled';
  if coalesce(cap, 0) - used + 1e-9 < p_est_kwh then
    raise exception 'Kapasitas slot tinggal % kWh. Pilih slot lain.', round(greatest(coalesce(cap, 0) - used, 0), 1);
  end if;
  if public.member_quota_available(me.id, p_date) + 1e-9 < p_est_kwh then
    raise exception 'Kuota energi Anda bulan ini tidak cukup. Minta kuota ke anggota lain di menu Perdagangan Energi.';
  end if;

  insert into hub_bookings (hub_id, slot_id, user_id, appliance_name, booking_date, est_kwh)
    values (hub.id, p_slot, me.id, p_appliance, p_date, p_est_kwh) returning * into b;
  return b;
end $$;

create function public.set_booking_status(p_booking uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare
  b hub_bookings;
  me profiles;
  coop uuid;
begin
  select * into me from profiles where id = auth.uid();
  select * into b from hub_bookings where id = p_booking;
  select cooperative_id into coop from solar_hubs where id = b.hub_id;
  if b.id is null or not (b.user_id = me.id or (me.role = 'admin' and me.cooperative_id = coop)) then
    raise exception 'Anda tidak bisa mengubah booking ini.';
  end if;
  if b.status <> 'booked' then raise exception 'Booking ini sudah selesai atau dibatalkan.'; end if;
  if p_status not in ('completed', 'cancelled') then raise exception 'Status tidak dikenal.'; end if;
  if p_status = 'completed' and b.booking_date > (now() at time zone 'Asia/Jakarta')::date then
    raise exception 'Pemakaian baru bisa dikonfirmasi pada atau setelah hari booking.';
  end if;
  update hub_bookings set status = p_status where id = p_booking;
end $$;

-- ---------------------------------------------------------------------------
-- Arisan
-- ---------------------------------------------------------------------------

create function public.create_arisan_group(p_name text, p_contribution bigint, p_start date, p_members uuid[])
returns arisan_groups language plpgsql security definer set search_path = public as $$
declare
  a profiles := private_require_admin();
  g arisan_groups;
  t uuid;
  i int;
begin
  if array_length(p_members, 1) is null or array_length(p_members, 1) < 2 then
    raise exception 'Grup arisan butuh minimal 2 anggota.';
  end if;
  if exists (
    select 1 from unnest(p_members) m left join profiles p on p.id = m
    where p.id is null or p.cooperative_id <> a.cooperative_id or p.role <> 'member'
  ) then
    raise exception 'Semua peserta harus anggota koperasi ini.';
  end if;
  insert into arisan_groups (cooperative_id, name, contribution_idr, start_month, created_by)
    values (a.cooperative_id, trim(p_name), p_contribution, date_trunc('month', p_start), a.id)
    returning * into g;
  insert into message_threads (cooperative_id, kind, title, ref_id)
    values (a.cooperative_id, 'group', g.name, g.id) returning id into t;
  insert into thread_participants (thread_id, user_id) values (t, a.id);
  for i in 1..array_length(p_members, 1) loop
    insert into arisan_members (group_id, user_id, turn_order) values (g.id, p_members[i], i);
    insert into thread_participants (thread_id, user_id) values (t, p_members[i]);
    perform private_notify(p_members[i], 'arisan', 'Anda masuk grup ' || g.name,
      'Giliran Anda ke-' || i || ' dari ' || array_length(p_members, 1) || '.', '/arisan');
  end loop;
  return g;
end $$;

create function public.submit_contribution(p_group uuid, p_note text default null)
returns arisan_payments language plpgsql security definer set search_path = public as $$
declare
  me profiles := private_require_member();
  g arisan_groups;
  pay arisan_payments;
  month date := date_trunc('month', now() at time zone 'Asia/Jakarta');
begin
  select * into g from arisan_groups where id = p_group;
  if not exists (select 1 from arisan_members where group_id = p_group and user_id = me.id) then
    raise exception 'Anda bukan anggota grup ini.';
  end if;
  if month < g.start_month then raise exception 'Arisan belum dimulai pada bulan itu.'; end if;
  insert into arisan_payments (group_id, user_id, type, amount_idr, period_month, status, note)
    values (p_group, me.id, 'contribution', g.contribution_idr, month, 'pending', nullif(trim(p_note), ''))
    returning * into pay;
  perform private_notify(a.id, 'payment', 'Setoran arisan menunggu konfirmasi',
    me.full_name || ' menyetor iuran ' || g.name || '.', '/a/payments')
  from profiles a where a.cooperative_id = g.cooperative_id and a.role = 'admin';
  return pay;
exception when unique_violation then
  raise exception 'Setoran bulan ini sudah dikirim.';
end $$;

create function public.review_payment(p_payment uuid, p_approve boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  a profiles := private_require_admin();
  pay arisan_payments;
  g arisan_groups;
begin
  select * into pay from arisan_payments where id = p_payment for update;
  select * into g from arisan_groups where id = pay.group_id;
  if g.cooperative_id <> a.cooperative_id then raise exception 'Setoran tidak ditemukan.'; end if;
  if pay.status <> 'pending' then raise exception 'Setoran ini sudah diproses.'; end if;
  if not p_approve and coalesce(trim(p_note), '') = '' then
    raise exception 'Tulis alasan penolakan agar anggota paham.';
  end if;
  update arisan_payments
    set status = case when p_approve then 'confirmed' else 'rejected' end,
        reviewed_by = a.id, reviewed_at = now(),
        note = coalesce(nullif(trim(p_note), ''), note)
    where id = p_payment;
  perform private_notify(pay.user_id, 'payment',
    case when p_approve then 'Iuran terkonfirmasi' else 'Setoran ditolak' end,
    case when p_approve then 'Iuran ' || g.name || ' sudah dicatat lunas.'
         else 'Setoran ' || g.name || ' ditolak: ' || trim(p_note) end,
    '/arisan');
end $$;

create function public.record_payout(p_group uuid, p_user uuid)
returns arisan_payments language plpgsql security definer set search_path = public as $$
declare
  a profiles := private_require_admin();
  g arisan_groups;
  n int;
  pay arisan_payments;
begin
  select * into g from arisan_groups where id = p_group;
  if g.cooperative_id <> a.cooperative_id then raise exception 'Grup arisan tidak ditemukan.'; end if;
  if not exists (select 1 from arisan_members where group_id = p_group and user_id = p_user) then
    raise exception 'Penerima bukan anggota grup ini.';
  end if;
  select count(*) into n from arisan_members where group_id = p_group;
  insert into arisan_payments (group_id, user_id, type, amount_idr, period_month, status, reviewed_by, reviewed_at)
    values (p_group, p_user, 'payout', g.contribution_idr * n,
            date_trunc('month', now() at time zone 'Asia/Jakarta'), 'confirmed', a.id, now())
    returning * into pay;
  perform private_notify(p_user, 'payment', 'Giliran arisan Anda dicairkan',
    'Dana ' || g.name || ' sudah dicatat diserahkan.', '/arisan');
  return pay;
exception when unique_violation then
  raise exception 'Pencairan untuk bulan ini sudah dicatat.';
end $$;

-- ---------------------------------------------------------------------------
-- Quota sharing (records agreements; no electricity moves)
-- ---------------------------------------------------------------------------

create function public.post_quota(p_kind text, p_kwh numeric, p_slot_note text, p_note text default null)
returns quota_offers language plpgsql security definer set search_path = public as $$
declare me profiles := private_require_member(); o quota_offers;
begin
  if p_kind = 'share' and public.member_quota_available(me.id, current_date) + 1e-9 < p_kwh then
    raise exception 'Kuota Anda bulan ini tidak cukup.';
  end if;
  insert into quota_offers (cooperative_id, owner_id, kind, kwh, slot_note, note)
    values (me.cooperative_id, me.id, p_kind, p_kwh, trim(coalesce(p_slot_note, '')), nullif(trim(p_note), ''))
    returning * into o;
  return o;
end $$;

create function public.respond_quota(p_offer uuid)
returns void language plpgsql security definer set search_path = public as $$
declare me profiles := private_require_member(); o quota_offers;
begin
  select * into o from quota_offers where id = p_offer for update;
  if o.cooperative_id <> me.cooperative_id then raise exception 'Penawaran tidak ditemukan.'; end if;
  if o.owner_id = me.id then raise exception 'Ini penawaran Anda sendiri.'; end if;
  if o.status <> 'open' then raise exception 'Penawaran ini sudah ditanggapi anggota lain.'; end if;
  if o.kind = 'need' and public.member_quota_available(me.id, current_date) + 1e-9 < o.kwh then
    raise exception 'Kuota Anda bulan ini tidak cukup.';
  end if;
  update quota_offers set status = 'pending', counterparty_id = me.id, updated_at = now() where id = p_offer;
  perform private_notify(o.owner_id, 'quota',
    case when o.kind = 'share' then me.full_name || ' meminta kuota Anda' else me.full_name || ' ingin memberi kuota' end,
    'Terima atau tolak di Perdagangan Energi.', '/quota');
end $$;

create function public.settle_quota(p_offer uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
declare me profiles; o quota_offers; giver uuid;
begin
  select * into me from profiles where id = auth.uid();
  select * into o from quota_offers where id = p_offer for update;
  if o.owner_id <> me.id then raise exception 'Hanya pembuat penawaran yang bisa memutuskan.'; end if;
  if o.status <> 'pending' or o.counterparty_id is null then
    raise exception 'Belum ada anggota yang menanggapi.';
  end if;
  giver := case when o.kind = 'share' then o.owner_id else o.counterparty_id end;
  if p_accept and public.member_quota_available(giver, current_date) + 1e-9 < o.kwh then
    raise exception 'Kuota pemberi sudah tidak cukup.';
  end if;
  update quota_offers
    set status = case when p_accept then 'completed' else 'open' end,
        counterparty_id = case when p_accept then counterparty_id else null end,
        updated_at = now()
    where id = p_offer;
  perform private_notify(o.counterparty_id, 'quota',
    case when p_accept then 'Pertukaran kuota disetujui' else 'Permintaan kuota ditolak' end,
    me.full_name || case when p_accept then ' menyetujui pertukaran.' else ' belum bisa menukar kuota kali ini.' end,
    '/quota');
end $$;

create function public.cancel_quota(p_offer uuid)
returns void language plpgsql security definer set search_path = public as $$
declare o quota_offers;
begin
  select * into o from quota_offers where id = p_offer for update;
  if o.owner_id <> auth.uid() then raise exception 'Hanya pembuat penawaran yang bisa membatalkan.'; end if;
  if o.status in ('completed', 'cancelled') then raise exception 'Penawaran ini sudah selesai.'; end if;
  update quota_offers set status = 'cancelled', updated_at = now() where id = p_offer;
  if o.counterparty_id is not null then
    perform private_notify(o.counterparty_id, 'quota', 'Penawaran kuota dibatalkan', 'Pembuat penawaran membatalkannya.', '/quota');
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Loans — status machine mirrors lib/core/logic/loan_math.dart
-- ---------------------------------------------------------------------------

create function private_loan_can_move(from_status text, to_status text) returns boolean
language sql immutable as $$
  select (from_status, to_status) in (
    ('submitted', 'in_review'), ('submitted', 'approved'), ('submitted', 'rejected'), ('submitted', 'cancelled'),
    ('in_review', 'approved'), ('in_review', 'rejected'),
    ('approved', 'disbursed'), ('approved', 'cancelled'),
    ('disbursed', 'repaid')
  )
$$;

create function private_loan_move(p_loan uuid, p_to text, p_actor uuid, p_note text, p_title text, p_body text)
returns loan_applications language plpgsql security definer set search_path = public as $$
declare l loan_applications; s uuid;
begin
  select * into l from loan_applications where id = p_loan for update;
  if not private_loan_can_move(l.status, p_to) then
    raise exception 'Pengajuan berstatus % tidak bisa diubah menjadi %.', l.status, p_to;
  end if;
  update loan_applications set status = p_to where id = p_loan returning * into l;
  insert into loan_events (loan_id, actor_id, type, note) values (p_loan, p_actor, p_to, p_note);
  if p_title is not null then
    perform private_notify(l.user_id, 'loan', p_title, p_body, '/loans/' || l.id);
    select id into s from message_threads where kind = 'support' and ref_id = l.user_id;
    if s is not null then
      insert into messages (thread_id, body) values (s, p_title || '. ' || p_body);
    end if;
  end if;
  return l;
end $$;

-- Inserted by the submit-loan Edge Function after it recomputes the score
-- and checks eligibility. Not callable by clients.
create function public.private_insert_loan(p_user uuid, p_amount bigint, p_purpose text, p_tenor int,
  p_note text, p_score int, p_band text, p_factors jsonb)
returns loan_applications language plpgsql security definer set search_path = public as $$
declare
  me profiles;
  c cooperatives;
  interest bigint;
  total bigint;
  l loan_applications;
begin
  select * into me from profiles where id = p_user and role = 'member';
  if me.id is null then raise exception 'Fitur ini khusus untuk anggota koperasi.'; end if;
  select * into c from cooperatives where id = me.cooperative_id;
  if not (p_tenor = any (c.loan_tenors)) then raise exception 'Tenor ini tidak disediakan koperasi.'; end if;
  if p_score < c.loan_min_score then raise exception 'Skor belum mencapai batas minimum koperasi.'; end if;
  interest := round(p_amount * c.loan_flat_monthly_rate_pct / 100 * p_tenor);
  total := p_amount + interest;
  insert into loan_applications (cooperative_id, user_id, amount_idr, purpose, tenor_months,
      flat_monthly_rate_pct, monthly_installment_idr, total_repayment_idr, note,
      score_snapshot, score_band, score_factors)
    values (c.id, me.id, p_amount, p_purpose, p_tenor, c.loan_flat_monthly_rate_pct,
      round(total::numeric / p_tenor), total, nullif(trim(p_note), ''), p_score, p_band, p_factors)
    returning * into l;
  insert into loan_events (loan_id, actor_id, type) values (l.id, me.id, 'submitted');
  perform private_notify(a.id, 'loan', 'Pengajuan pinjaman baru',
    me.full_name || ' mengajukan pinjaman.', '/a/loans/' || l.id)
  from profiles a where a.cooperative_id = c.id and a.role = 'admin';
  return l;
exception when unique_violation then
  raise exception 'Selesaikan pinjaman yang masih berjalan sebelum mengajukan lagi.';
end $$;
revoke execute on function public.private_insert_loan from public, anon, authenticated;

create function public.cancel_loan(p_loan uuid) returns void
language plpgsql security definer set search_path = public as $$
declare l loan_applications;
begin
  select * into l from loan_applications where id = p_loan;
  if l.user_id <> auth.uid() then raise exception 'Anda tidak bisa membatalkan pengajuan ini.'; end if;
  if l.status <> 'submitted' then
    raise exception 'Pengajuan yang sudah direview tidak bisa dibatalkan sendiri. Hubungi admin.';
  end if;
  perform private_loan_move(p_loan, 'cancelled', auth.uid(), null, null, null);
end $$;

create function public.admin_loan_action(p_loan uuid, p_action text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  a profiles := private_require_admin();
  l loan_applications;
  i int;
  base bigint;
  t timestamptz := now();
begin
  select * into l from loan_applications where id = p_loan;
  if l.cooperative_id <> a.cooperative_id then raise exception 'Pengajuan tidak ditemukan.'; end if;

  if p_action = 'start_review' then
    perform private_loan_move(p_loan, 'in_review', a.id, null,
      'Pengajuan sedang direview', 'Admin ' || a.full_name || ' sedang memeriksa pengajuan Anda.');
  elsif p_action = 'approve' then
    update loan_applications set decision_note = nullif(trim(p_note), ''), decided_by = a.id, decided_at = t where id = p_loan;
    perform private_loan_move(p_loan, 'approved', a.id, nullif(trim(p_note), ''),
      'Pengajuan disetujui', 'Dana akan dicairkan oleh koperasi.');
  elsif p_action = 'reject' then
    if coalesce(trim(p_note), '') = '' then raise exception 'Tulis alasan penolakan agar anggota paham.'; end if;
    update loan_applications set decision_note = trim(p_note), decided_by = a.id, decided_at = t where id = p_loan;
    perform private_loan_move(p_loan, 'rejected', a.id, trim(p_note),
      'Pengajuan belum disetujui', 'Alasan dari admin: ' || trim(p_note));
  elsif p_action = 'disburse' then
    perform private_loan_move(p_loan, 'disbursed', a.id, null,
      'Dana pinjaman dicairkan', 'Cicilan dimulai bulan depan.');
    update loan_applications set disbursed_at = t where id = p_loan;
    base := l.total_repayment_idr / l.tenor_months;
    for i in 1..l.tenor_months loop
      insert into loan_installments (loan_id, seq, due_date, amount_idr)
        values (p_loan, i, (t::date + make_interval(months => i))::date,
                case when i = l.tenor_months then l.total_repayment_idr - base * (l.tenor_months - 1) else base end);
    end loop;
  else
    raise exception 'Aksi tidak dikenal.';
  end if;
end $$;

create function public.mark_installment_paid(p_installment uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  a profiles := private_require_admin();
  inst loan_installments;
  l loan_applications;
begin
  select * into inst from loan_installments where id = p_installment for update;
  select * into l from loan_applications where id = inst.loan_id;
  if l.cooperative_id <> a.cooperative_id then raise exception 'Cicilan tidak ditemukan.'; end if;
  if l.status <> 'disbursed' then raise exception 'Pinjaman ini tidak sedang berjalan.'; end if;
  if inst.paid_at is not null then raise exception 'Cicilan ini sudah dicatat lunas.'; end if;
  update loan_installments set paid_at = now(), confirmed_by = a.id where id = p_installment;
  insert into loan_events (loan_id, actor_id, type, note)
    values (l.id, a.id, 'installment_paid', 'Cicilan ke-' || inst.seq);
  if not exists (select 1 from loan_installments where loan_id = l.id and paid_at is null) then
    perform private_loan_move(l.id, 'repaid', a.id, null, 'Pinjaman lunas', 'Semua cicilan sudah tercatat lunas.');
  else
    perform private_notify(l.user_id, 'loan', 'Cicilan ke-' || inst.seq || ' tercatat',
      'Pembayaran sudah dikonfirmasi admin.', '/loans/' || l.id);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Messaging side effects
-- ---------------------------------------------------------------------------

create function private_on_announcement() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.sender_id is not null and (select kind from message_threads where id = new.thread_id) = 'announcement' then
    insert into notifications (user_id, type, title, body, route)
      select tp.user_id, 'announcement', 'Pengumuman koperasi', left(new.body, 140), '/thread/' || new.thread_id
      from thread_participants tp where tp.thread_id = new.thread_id and tp.user_id <> new.sender_id;
  end if;
  return new;
end $$;
create trigger announcement_notify after insert on public.messages
  for each row execute function private_on_announcement();

create function public.direct_thread(p_other uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare me profiles; other profiles; t uuid;
begin
  select * into me from profiles where id = auth.uid();
  select * into other from profiles where id = p_other;
  if other.id is null or other.cooperative_id <> me.cooperative_id then
    raise exception 'Anggota tidak ditemukan.';
  end if;
  select tp.thread_id into t from thread_participants tp
    join message_threads mt on mt.id = tp.thread_id and mt.kind = 'direct'
    where tp.user_id = me.id
      and exists (select 1 from thread_participants x where x.thread_id = tp.thread_id and x.user_id = other.id)
    limit 1;
  if t is null then
    insert into message_threads (cooperative_id, kind, title) values (me.cooperative_id, 'direct', '') returning id into t;
    insert into thread_participants (thread_id, user_id) values (t, me.id), (t, other.id);
  end if;
  return t;
end $$;

-- Realtime: members see new messages, notifications and status changes live.
alter publication supabase_realtime add table
  public.messages, public.notifications, public.loan_applications,
  public.arisan_payments, public.quota_offers, public.hub_bookings;
