-- Star Chicken Online — Supabase setup (run ONCE in: Supabase Dashboard > SQL Editor > New query > Run)

create table if not exists public.sc_records (
  coll       text        not null,              -- collection: users, products, stock, transfers, sales, ...
  id         text        not null,              -- record id
  data       jsonb,                             -- the record itself
  deleted    boolean     not null default false,-- soft delete (so other devices learn about deletions)
  ord        bigint      not null default 0,    -- keeps list order (newest-first / oldest-first)
  updated_by text,
  updated_at timestamptz not null default now(),
  primary key (coll, id)
);

create index if not exists sc_records_updated_idx on public.sc_records (updated_at);

create or replace function public.sc_touch() returns trigger
language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

drop trigger if exists sc_touch_trg on public.sc_records;
create trigger sc_touch_trg before insert or update on public.sc_records
  for each row execute function public.sc_touch();

alter table public.sc_records enable row level security;
drop policy if exists sc_all on public.sc_records;
create policy sc_all on public.sc_records for all to anon, authenticated using (true) with check (true);

-- live (realtime) updates between devices
do $$ begin
  alter publication supabase_realtime add table public.sc_records;
exception when duplicate_object then null; end $$;
