-- Garante tipo_cozinha minimo
INSERT INTO tipo_cozinha (tipo) VALUES ('Pizzaria') ON CONFLICT DO NOTHING;

-- Garante restaurante
INSERT INTO restaurante (pessoa_id, nome, status_funcionamento, tipo_cozinha_id)
SELECT p.pessoa_id, 'Pizzaria do Joao', TRUE, tc.id
FROM pessoa p, tipo_cozinha tc
WHERE p.cpf_cnpj = '22222222000122' AND tc.tipo = 'Pizzaria'
AND NOT EXISTS (SELECT 1 FROM restaurante WHERE nome = 'Pizzaria do Joao');

-- Garante produtos
INSERT INTO produto (nome, tipo, preco, custo, restaurante_id)
SELECT 'Pizza Margherita', 'Pizza', 45.00, 18.00, r.id
FROM restaurante r WHERE r.nome = 'Pizzaria do Joao'
AND NOT EXISTS (SELECT 1 FROM produto WHERE nome = 'Pizza Margherita');

INSERT INTO produto (nome, tipo, preco, custo, restaurante_id)
SELECT 'Refrigerante Lata', 'Bebida', 7.00, 2.50, r.id
FROM restaurante r WHERE r.nome = 'Pizzaria do Joao'
AND NOT EXISTS (SELECT 1 FROM produto WHERE nome = 'Refrigerante Lata');

INSERT INTO produto (nome, tipo, preco, custo, restaurante_id)
SELECT 'Pizza Calabresa', 'Pizza', 49.00, 19.50, r.id
FROM restaurante r WHERE r.nome = 'Pizzaria do Joao'
AND NOT EXISTS (SELECT 1 FROM produto WHERE nome = 'Pizza Calabresa');

-- Garante entregadores
INSERT INTO entregador (pessoa_id, disponivel, latitude, longitude)
SELECT p.pessoa_id, TRUE, -26.17, -49.18
FROM pessoa p
WHERE p.nome = 'Carlos Moto'
AND NOT EXISTS (SELECT 1 FROM entregador e WHERE e.pessoa_id = p.pessoa_id);

INSERT INTO entregador (pessoa_id, disponivel, latitude, longitude)
SELECT p.pessoa_id, TRUE, -26.18, -49.19
FROM pessoa p
WHERE p.nome = 'Marina Entrega'
AND NOT EXISTS (SELECT 1 FROM entregador e WHERE e.pessoa_id = p.pessoa_id);
