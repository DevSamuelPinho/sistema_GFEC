-- ==============================================================================
-- SISTEMA GFEC - Gestão Financeira Em Casal
-- v2.0 - Sistema de Família (family_id) para isolamento multi-casal
-- Execute este script no Supabase: SQL Editor > New Query > Run
-- ATENÇÃO: Se você já executou a versão anterior, execute apenas a seção
--          "MIGRAÇÃO" ao final, não o bloco CREATE TABLE completo.
-- ==============================================================================


-- ==============================================================================
-- 1. TABELA DE FAMÍLIAS (GRUPOS/CASAIS)
-- ==============================================================================
create table if not exists families (
  id uuid primary key default gen_random_uuid(),
  invite_code text unique not null default upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
  criado_em timestamptz default now()
);

-- ==============================================================================
-- 2. TABELAS PRINCIPAIS (com family_id)
-- ==============================================================================
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  family_id uuid references families(id) on delete set null,
  nome text not null default '',
  pct int not null default 50 check(pct between 0 and 100),
  chave_pix text default ''
);

create table if not exists cards (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  owner uuid references auth.users on delete set null,
  nome text not null,
  limite numeric not null default 0,
  fechamento int not null check(fechamento between 1 and 31),
  vencimento int not null check(vencimento between 1 and 31),
  cor text default 'indigo'
);

create table if not exists purchases (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  card_id uuid references cards on delete set null,
  descricao text not null,
  valor_parcela numeric not null check(valor_parcela > 0),
  n_parcelas int not null default 1 check(n_parcelas >= 1),
  parcela_atual int not null default 1 check(parcela_atual >= 1),
  data date not null,
  resp text not null default 'eu' check(resp in ('eu','ambos','empresa','receber')),
  categoria text default 'Outros'
);

create table if not exists incomes (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  tipo text not null,
  descricao text,
  valor numeric not null check(valor >= 0),
  fixo boolean not null default true,
  mes text
);

create table if not exists acertos (
  mes text not null,
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  criado_em timestamptz default now(),
  primary key (mes, family_id)
);

-- ==============================================================================
-- 3. MIGRAÇÕES SEGURAS (execute se já tinha a versão anterior)
-- ==============================================================================
alter table profiles add column if not exists family_id uuid references families(id) on delete set null;
alter table profiles add column if not exists chave_pix text default '';
alter table cards    add column if not exists family_id uuid references families(id) on delete cascade;
alter table cards    add column if not exists cor text default 'indigo';
alter table purchases add column if not exists family_id uuid references families(id) on delete cascade;
alter table purchases add column if not exists categoria text default 'Outros';
alter table incomes  add column if not exists family_id uuid references families(id) on delete cascade;

-- ==============================================================================
-- 4. HABILITAR RLS
-- ==============================================================================
alter table families  enable row level security;
alter table profiles  enable row level security;
alter table cards     enable row level security;
alter table purchases enable row level security;
alter table incomes   enable row level security;
alter table acertos   enable row level security;

-- ==============================================================================
-- 5. FUNÇÕES AUXILIARES
-- ==============================================================================

-- Retorna o family_id do usuário logado (sem expor dados de outros)
create or replace function my_family_id()
returns uuid language sql stable security definer as $$
  select family_id from profiles where id = auth.uid() limit 1;
$$;

-- ==============================================================================
-- 6. POLÍTICAS DE ACESSO (RLS) - Isolamento por Família
-- ==============================================================================

-- FAMILIES: qualquer usuário autenticado pode criar; só membros podem ver a sua
drop policy if exists fam_sel on families;
create policy fam_sel on families for select to authenticated
  using (id = my_family_id());

drop policy if exists fam_ins on families;
create policy fam_ins on families for insert to authenticated
  with check (true);

-- PROFILES: visível para membros da mesma família; editável só pelo próprio
drop policy if exists p_sel on profiles;
create policy p_sel on profiles for select to authenticated
  using (family_id = my_family_id() or id = auth.uid());

drop policy if exists p_ins on profiles;
create policy p_ins on profiles for insert to authenticated
  with check (id = auth.uid());

drop policy if exists p_upd on profiles;
create policy p_upd on profiles for update to authenticated
  using (id = auth.uid());

-- CARDS: acessível apenas pela mesma família
drop policy if exists c_sel on cards;
create policy c_sel on cards for select to authenticated
  using (family_id = my_family_id());

drop policy if exists c_ins on cards;
create policy c_ins on cards for insert to authenticated
  with check (family_id = my_family_id());

drop policy if exists c_upd on cards;
create policy c_upd on cards for update to authenticated
  using (family_id = my_family_id() and (owner is null or owner = auth.uid()));

drop policy if exists c_del on cards;
create policy c_del on cards for delete to authenticated
  using (family_id = my_family_id() and (owner is null or owner = auth.uid()));

-- PURCHASES: acessível apenas pela mesma família
drop policy if exists b_sel on purchases;
create policy b_sel on purchases for select to authenticated
  using (family_id = my_family_id());

drop policy if exists b_ins on purchases;
create policy b_ins on purchases for insert to authenticated
  with check (family_id = my_family_id() and user_id = auth.uid());

drop policy if exists b_upd on purchases;
create policy b_upd on purchases for update to authenticated
  using (family_id = my_family_id() and user_id = auth.uid());

drop policy if exists b_del on purchases;
create policy b_del on purchases for delete to authenticated
  using (family_id = my_family_id() and user_id = auth.uid());

-- INCOMES: privadas, mas isoladas por família
drop policy if exists i_all on incomes;
create policy i_all on incomes for all to authenticated
  using (family_id = my_family_id() and user_id = auth.uid())
  with check (family_id = my_family_id() and user_id = auth.uid());

-- ACERTOS: compartilhados dentro da família
drop policy if exists a_sel on acertos;
create policy a_sel on acertos for select to authenticated
  using (family_id = my_family_id());

drop policy if exists a_ins on acertos;
create policy a_ins on acertos for insert to authenticated
  with check (family_id = my_family_id() and user_id = auth.uid());

drop policy if exists a_del on acertos;
create policy a_del on acertos for delete to authenticated
  using (family_id = my_family_id());

-- ==============================================================================
-- 7. ÍNDICES DE PERFORMANCE
-- ==============================================================================
create index if not exists idx_profiles_family    on profiles(family_id);
create index if not exists idx_cards_family       on cards(family_id);
create index if not exists idx_purchases_family   on purchases(family_id, data);
create index if not exists idx_purchases_resp     on purchases(resp);
create index if not exists idx_incomes_family     on incomes(family_id, user_id);
create index if not exists idx_families_invite    on families(invite_code);

-- ==============================================================================
-- 8. FUNÇÃO RPC - Busca família pelo código de convite (bypass seguro do RLS)
-- Usada no frontend para encontrar a família de outra pessoa pelo código de convite
-- sem precisar expor todas as famílias.
-- ==============================================================================
create or replace function get_family_by_invite(code text)
returns table(id uuid, invite_code text)
language sql stable security definer as $$
  select id, invite_code from families where invite_code = upper(code) limit 1;
$$;

