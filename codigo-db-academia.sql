create table alunos (
    id serial primary key,
    nome varchar(100) not null,
    email varchar(100) unique not null,
    cpf varchar(11) unique not null,
    telefone varchar(20) not null,
    data_cadastro timestamp default current_timestamp
);

create table planos (
    id serial primary key,
    nome varchar(50) unique not null,
    valor_mensal_base decimal(10,2) check (valor_mensal_base > 0) not null
);

create table modalidades (
    id serial primary key,
    plano_id int references planos(id),
    nome varchar(100) not null,
    sala varchar(20) not null,
    capacidade_maxima int check (capacidade_maxima > 0) not null,
    disponivel boolean default true
);

create table matriculas (
    id serial primary key,
    aluno_id int references alunos(id),
    data_inicio timestamp default current_timestamp,
    status varchar(20) default 'Ativa' check (status in ('Ativa', 'Cancelada', 'Trancada'))
);

create table itens_matricula (
    id serial primary key,
    matricula_id int references matriculas(id),
    modalidade_id int references modalidades(id),
    duracao_meses int check (duracao_meses > 0) not null,
    valor_mensal_aplicado decimal(10,2) check (valor_mensal_aplicado > 0) not null,
    taxa_adesao decimal(10,2) check (taxa_adesao >= 0) default 0.00
);

insert into planos (nome, valor_mensal_base) values 
('VIP Premium', 220.00), 
('Fitness Standard', 140.00), 
('Basic Fit', 90.00);

insert into modalidades (plano_id, nome, sala, capacidade_maxima, disponivel) values 
(1, 'Crossfit Pro', 'Arena 01', 15, true),
(2, 'Pilates Avançado', 'Studio 02', 10, true),
(3, 'Musculação Livre', 'Salão Principal', 50, true);

insert into alunos (nome, email, cpf, telefone) values 
('Carlos Silva', 'carlos@email.com', '11122233344', '11999990000'),
('Ana Lima', 'ana@email.com', '22233344455', '11988880000'),
('Beatriz Costa', 'bea@email.com', '33344455566', '11977770000');

insert into matriculas (aluno_id, status) values 
(1, 'Ativa'), 
(1, 'Ativa'), 
(2, 'Ativa'), 
(3, 'Cancelada');

insert into itens_matricula (matricula_id, modalidade_id, duracao_meses, valor_mensal_aplicado, taxa_adesao) values 
(1, 1, 6, 220.00, 50.00),
(2, 2, 3, 140.00, 30.00),
(3, 3, 12, 90.00, 0.00),
(4, 1, 1, 220.00, 50.00);

create view vw_modalidades_custo_estimado as
select 
    m.nome as modalidade, 
    m.sala, 
    p.nome as plano, 
    round(p.valor_mensal_base * 1.10, 2) as mensalidade_com_taxa
from modalidades m
join planos p on m.plano_id = p.id
order by mensalidade_com_taxa desc;

create view vw_matriculas_ativas as
select 
    a.nome as aluno, 
    a.cpf, 
    mod.nome as modalidade, 
    mod.sala, 
    im.duracao_meses, 
    mat.data_inicio
from matriculas mat
join alunos a on mat.aluno_id = a.id
join itens_matricula im on mat.id = im.matricula_id
join modalidades mod on im.modalidade_id = mod.id
where mat.status = 'Ativa';

create view vw_alunos_vip as
select 
    a.nome as aluno, 
    count(mat.id) as total_matriculas, 
    sum((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) as total_investido
from alunos a
join matriculas mat on a.id = mat.aluno_id
join itens_matricula im on mat.id = im.matricula_id
where mat.status = 'Ativa'
group by a.id, a.nome
having sum((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) > 1000.00;

select m.*, p.nome as plano, p.valor_mensal_base
from modalidades m
join planos p on m.plano_id = p.id
where m.capacidade_maxima >= 15 
  and p.valor_mensal_base > 100.00 
  and m.disponivel = true;

create view vw_faturamento_medio_plano as
select 
    p.nome as plano, 
    sum((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) as faturamento_total,
    round(avg(im.duracao_meses), 1) as media_meses_contratados
from itens_matricula im
join matriculas mat on im.matricula_id = mat.id
join modalidades m on im.modalidade_id = m.id
join planos p on m.plano_id = p.id
where mat.status = 'Ativa'
group by p.nome;
