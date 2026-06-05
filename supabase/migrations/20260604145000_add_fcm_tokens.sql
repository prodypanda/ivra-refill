create table user_fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  device_type text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, token)
);

alter table user_fcm_tokens enable row level security;

create policy "Users can view their own tokens"
  on user_fcm_tokens for select
  using (auth.uid() = user_id);

create policy "Users can insert their own tokens"
  on user_fcm_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own tokens"
  on user_fcm_tokens for update
  using (auth.uid() = user_id);

create policy "Users can delete their own tokens"
  on user_fcm_tokens for delete
  using (auth.uid() = user_id);

create or replace function register_fcm_token(p_token text, p_device_type text)
returns void
language plpgsql
security definer
as $$
begin
  insert into user_fcm_tokens (user_id, token, device_type, updated_at)
  values (auth.uid(), p_token, p_device_type, now())
  on conflict (user_id, token) do update
  set updated_at = now();
end;
$$;
